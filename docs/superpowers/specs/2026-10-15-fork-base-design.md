# Neverwas — Subproyecto A: fork base

- **Fecha:** 2026-10-15
- **Estado:** aprobado en chat, pendiente de revisión escrita
- **Base:** Bulk Crap Uninstaller (BCU) v6.3, commit `30da6093` de `Klocman/Bulk-Crap-Uninstaller` (Apache 2.0)

## Objetivo

Tener un fork de BCU llamado **Neverwas** que compile, pase los tests de upstream, se presente con
marca propia, no contacte servidores de terceros y pueda seguir recibiendo las versiones de upstream
con un costo de merge cercano a cero. Es la base sobre la que se construye el subproyecto B
(monitor de instalaciones con ETW).

## Contexto

Neverwas apunta a igualar y superar a Revo Uninstaller Pro, gratis. Se parte de BCU porque ya
cubre desinstalación masiva, escaneo de restos con confianza, apps huérfanas, Store/Steam/Chocolatey/
Scoop, autoarranque y modo "target". Lo que le falta frente a Revo (seguimiento de instalaciones)
es el subproyecto B. Revo **no** se decompila ni se analiza: su EULA (cláusula 1) lo prohíbe, y
su único uso es como lista de funciones, sacada del PDF de ayuda y de la interfaz.

Stack heredado: C# / .NET 8 (`net8.0-windows10.0.18362.0`), WinForms, ~128K líneas en 20
proyectos, solución `source/BulkCrapUninstaller.sln`, launcher nativo C++ (`BCU-launcher`).

## Decisiones

| Decisión | Elegido | Descartado y por qué |
|---|---|---|
| Estrategia de fork | **Liviano**: solo lo visible cambia | Completo (renombrar namespaces): cada merge de upstream choca en cientos de archivos. App separada: el monitor no se integraría a la lista |
| Hosting | GitHub `ErickuchoSan/Neverwas` + push mirror a Forgejo | Solo Forgejo: el runner es Linux y no corre tests WinForms |
| Rama principal | `main` | `master` de upstream queda como referencia local |
| Marca en traducciones | Script idempotente `tools/rebrand.ps1` | Edición a mano de 22 idiomas: conflictos en cada merge de traducciones |
| Alcance de publicación | Pensado para publicarse, pero A no incluye instalador ni release | — |

## Diseño

### 1. Repositorio y ramas

- Carpeta local `D:\Desarrollos\Neverwas`, con `core.longpaths=true`.
- Remotos:
  - `origin` → `https://github.com/ErickuchoSan/Neverwas` (fork en GitHub de `Klocman/Bulk-Crap-Uninstaller`, renombrado)
  - `upstream` → `https://github.com/Klocman/Bulk-Crap-Uninstaller`
  - `forgejo` → `ssh://git@100.123.247.5:2222/ErickuchoSan/Neverwas.git` (espejo, solo push)
- `main` es la rama de Neverwas. El trabajo entra por ramas `feature/*`, `fix/*`, `chore/*` y PR.
- Sincronizar con upstream: rama `chore/sync-upstream-vX.Y` → `git merge upstream/master` →
  procedimiento de la sección 2.3 → PR a `main`.

### 2. Cambio de marca

#### 2.1 Qué cambia

| Elemento | Antes | Después | Dónde |
|---|---|---|---|
| Ejecutable GUI | `BCUninstaller.exe` | `Neverwas.exe` | `<AssemblyName>` en `BulkCrapUninstaller.csproj` |
| Ejecutable consola | `BCU-console.exe` | `neverwas-cli.exe` | `<AssemblyName>` en `BCU-console.csproj` |
| Producto | `Bulk Crap Uninstaller` | `Neverwas` | `<Product>` en csproj / `Directory.Build.props` |
| Launcher nativo | busca `BCUninstaller.exe` | busca `Neverwas.exe` | `BCU-launcher/main.cpp`, `.rc` |
| Íconos | logo de BCU | ícono provisorio de Neverwas | `Resources/logo.ico` y los `<ApplicationIcon>` del launcher/consola |
| Títulos, "Acerca de" | BCU | Neverwas + crédito "basado en Bulk Crap Uninstaller de Marcin Szeniak" | `.resx` neutros e `Localisable` |
| Configuración | `BCUninstaller.settings` junto al exe | `Neverwas.settings` junto al exe | Automático: `Program.cs` arma el nombre con el nombre del exe |

La configuración es portable (archivo junto al ejecutable, ver `Program.cs` y
`PortableSettingsProvider`). Al cambiar el nombre del exe, el archivo cambia solo, y Neverwas
convive con un BCU instalado en otra carpeta.

#### 2.2 Qué NO cambia

Namespaces (`BulkCrapUninstaller.*`, `UninstallTools.*`, `Klocman.*`), nombres de proyectos y de
carpetas, cabeceras de copyright de los archivos existentes, `Licence.txt`.

#### 2.3 `tools/rebrand.ps1`

- Reemplaza las cadenas de marca **visibles** en todos los `.resx` (neutros y los 22 idiomas) y en
  los archivos de la tabla 2.1 que no se editen a mano.
- Lista de reemplazos explícita y versionada dentro del script (p. ej. `Bulk Crap Uninstaller` →
  `Neverwas`, `BCUninstaller` → `Neverwas`), con exclusiones para cabeceras de copyright, URLs de
  atribución y nombres de tipos o namespaces.
- **Idempotente:** correrlo dos veces deja el árbol igual que correrlo una.
- Modo `-Check`: sale con código ≠ 0 si quedan cadenas sin reemplazar (lo usa la CI).
- Procedimiento de merge con upstream: en conflictos de `.resx` se toma la versión de upstream
  (`git checkout --theirs`), se corre `tools/rebrand.ps1`, se verifica con `-Check`.

### 3. Red y privacidad

Hoy BCU contacta a servidores de Klocman. En Neverwas:

| Componente | Endpoint actual | Acción |
|---|---|---|
| Reporte de crashes (NBug) | `http://bugsklocman.ddns.net:7721` (`Program.ConnectionString`) | **Apagado.** El diálogo de error queda local, sin opción de enviar |
| Calificaciones (`UninstallerRatingManager`) | mismo host, rutas relativas | **Apagado.** Columna de calificación oculta y sin peticiones |
| Actualizaciones (`UpdateGrabber.LatestReleaseUrl`) | `github.com/Klocman/.../releases/latest` | **Reapuntado** a `github.com/ErickuchoSan/Neverwas/releases/latest` |
| Links de donación y contacto | `klocmansoftware.weebly.com` | Reemplazados por el repo de Neverwas; el crédito a BCU se mantiene en "Acerca de" |

Regla: Neverwas solo contacta GitHub (actualizaciones) y los servicios que el usuario dispare
a mano (por ejemplo "buscar en la web").

### 4. Build y CI

- `.github/workflows/ci.yaml` se adapta del de upstream (`windows-2022`, msbuild Restore + Publish,
  launcher C++, `dotnet test`, artefactos). Dispara en `push` a `main` y en `pull_request`.
- Pasos nuevos:
  1. `tools/rebrand.ps1 -Check`.
  2. Guardia de endpoints: falla si aparece `bugsklocman`, `klocmansoftware` o
     `Klocman/Bulk-Crap-Uninstaller/releases` fuera de comentarios, `NOTICE`, `README` o créditos.
- `winget.yml` de upstream se elimina: publica el paquete de Klocman.
- Espejo a Forgejo: push mirror configurado en Forgejo (sin workflow en Forgejo).
- Build local de referencia: `msbuild source\BulkCrapUninstaller.sln /t:Restore;Build /p:Configuration=Release /p:Platform="Any CPU"`
  y `dotnet test source\BulkCrapUninstallerTests\BulkCrapUninstallerTests.csproj`.

### 5. Legal

- Se conservan `Licence.txt` (Apache 2.0) y `NOTICE`. A `NOTICE` se le agrega:
  "Neverwas — modified by Erick Bores, 2026. Based on Bulk Crap Uninstaller by Marcin Szeniak."
- Archivos modificados de forma sustancial llevan una línea "Modified by Erick Bores, 2026" en la cabecera
  (Apache 2.0, sección 4b).
- `README.md` nuevo: qué es Neverwas, que es un fork de BCU con link, licencia, cómo compilar.
- El nombre "Bulk Crap Uninstaller" solo aparece como atribución (Apache 2.0, sección 6).

## Criterios de aceptación

A está terminado cuando, **con evidencia pegada** de cada punto:

1. La CI en GitHub queda en verde en `main`: build, launcher, tests de upstream, `rebrand.ps1 -Check`
   y guardia de endpoints.
2. `Neverwas.exe` (build Release local) abre, lista los programas instalados de esta máquina y crea
   `Neverwas.settings` junto al exe. No lee ni escribe `BCUninstaller.settings`.
3. Con la app abierta y una desinstalación de prueba cancelada, no hay conexiones a
   `bugsklocman.ddns.net` (verificado con `Get-NetTCPConnection` filtrando por el PID del proceso, o con Resource Monitor).
4. `neverwas-cli.exe --help` corre y muestra la marca Neverwas.
5. Merge de prueba: en una rama descartable, `git merge upstream/master` desde un commit anterior
   de upstream + procedimiento 2.3 deja `-Check` en verde sin editar `.resx` a mano.
6. `NOTICE`, `Licence.txt` y `README.md` cumplen la sección 5.
7. `forgejo` refleja `main` después de un push a `origin`.

## Fuera de alcance

- Monitor de instalaciones con ETW y desinstalación desde log (subproyecto B).
- Escaneo híbrido de restos (C), limpiadores extra (D), interfaz nueva (E).
- Logo definitivo e identidad visual (se hará con `brand-system`).
- Instalador, firma de código, releases publicados, paquete de winget.
- Renombrar namespaces o reestructurar proyectos.

## Riesgos

| Riesgo | Mitigación |
|---|---|
| Upstream cambia cadenas de marca o agrega nuevas | `-Check` en CI las detecta en el PR de sync |
| El fork de GitHub queda público | Aceptado: el proyecto se va a publicar y la licencia lo permite |
| Algún componente arma URLs de Klocman de forma dinámica y la guardia no lo ve | Criterio 3 verifica el comportamiento en ejecución, no solo el texto |
