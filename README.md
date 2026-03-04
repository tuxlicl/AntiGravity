# AntiGravity
Repositorio central para la gestión y sincronización de scripts y automatizaciones (PowerShell, Palo Alto, Windows) utilizando el asistente de IA Antigravity.

## Características
- **Skills Personalizadas:** Ubicados en la carpeta oculta `.agents/skills` para potenciar las respuestas de Antigravity (Ej. `powershell_master`, `paloalto_expert`).
- **Scripts Multiplataforma:** Organizados en la carpeta `Script` bajo los subdirectorios `Windows`, `Linux` y `PowerShell`.

---

## 🚀 Guía de Instalación para Entornos Remotos (VDI / Bastión)

Para conectar tu entorno de trabajo en la oficina (Mac) con tu entorno remoto (VDI Windows) y mantener todos los scripts y perfiles sincronizados, sigue estos pasos desde la VDI:

### 1. Requisitos Previos (Instalación)
Descarga e instala en tu equipo remoto las siguientes herramientas:

1. **[Git para Windows](https://gitforwindows.org/)**
   - Necesario para clonar y sincronizar este repositorio.
   - *Nota:* Puedes dejar las opciones por defecto durante la instalación. Asegúrate de que Git se agregue a la variable de entorno PATH (suele venir marcado).
2. **[Visual Studio Code (VS Code)](https://code.visualstudio.com/)**
   - Tu editor de código principal donde correrá Antigravity.
3. **Extensión de Antigravity**
   - Abre VS Code, ve al panel de *Extensiones* (Ctrl+Shift+X), busca e instala **Antigravity**.
   - Inicia sesión con tus credenciales.

---

### 2. Sincronización Inicial (Clonar el Repositorio)
Una vez instalados los requisitos previos, abre una **Terminal en VS Code** (Terminal -> New Terminal o `Ctrl + \``) y ejecuta:

```bash
# 1. Clona este repositorio a tu VDI
git clone https://github.com/tuxlicl/AntiGravity.git

# 2. Entra a la carpeta
cd AntiGravity
```

### 3. ¡Empieza a Trabajar!
- **Abre la carpeta `AntiGravity`** desde el menú `File > Open Folder...` en VS Code.
- Al abrir la carpeta, Antigravity **leerá automáticamente** todas las personalizaciones y *Skills* de la carpeta `.agents/skills`.
- Puedes crear y modificar scripts en la carpeta `Script`.
- Para **guardar y subir tus cambios** al repositorio de GitHub y que estén disponibles en tu Mac, ejecuta desde la terminal:

```bash
git add .
git commit -m "Descripción de tu cambio"
git push origin main
```

- Para **recibir (descargar) los últimos cambios** que hayas hecho desde tu Mac y sincronizar tu VDI:

```bash
git pull origin main
```

*(Opcional) Nota sobre PowerShell Remoto:* Si tus scripts interactúan con Active Directory o equipos de red, asegúrate de tener instalados los módulos correspondientes en tu VDI o Bastión (Ej: `RSAT` para AD, Módulos propios de Palo Alto `pan-os-python`, etc).
