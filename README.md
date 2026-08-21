# CampusTask

CampusTask es un prototipo universitario nativo para iPhone construido con SwiftUI. Demuestra concurrencia, consumo de API REST, `Codable`, `UserDefaults`, Keychain y persistencia offline con SwiftData dentro de un único flujo coherente.

**Creadores:** Milton, Angel, Walter, Leonel y Carlos.

## Funciones incluidas

- Inicio de sesión real contra una API de demostración.
- Token de sesión almacenado en Keychain.
- Carga simultánea de perfil, actividades y materias con `async let`.
- Peticiones `GET`, `POST` y `PATCH` mediante `URLSession`.
- Validación de códigos HTTP antes de decodificar.
- Modelos `Codable` con `CodingKeys`, opcionales, fechas y `convertFromSnakeCase`.
- Dashboard con actividades pendientes, completadas y vencidas.
- Creación y cambio de estado de actividades.
- Persistencia local con SwiftData.
- Cola de cambios realizados sin conexión.
- Sincronización automática cuando vuelve la red.
- Preferencias de apariencia y filtros con `@AppStorage`/UserDefaults.
- Pantalla especial para explicar los temas 5.1 a 5.5.

## Requisitos

- iPhone con iOS 17 o posterior.
- Repositorio de GitHub.
- Windows con Sideloadly para firmar e instalar el IPA.
- No se necesita una Mac propia: GitHub Actions compila con Xcode en macOS.

## Cuenta pública de demostración

```text
Usuario: emilys
Contraseña: emilyspass
```

Estas credenciales pertenecen a DummyJSON y no contienen información personal. No deben reemplazarse por contraseñas reales.

Si no hay internet, la pantalla de acceso incluye **Entrar en modo demostración offline**.

## Compilar el IPA desde GitHub

1. Crear un repositorio y subir el contenido de esta carpeta manteniendo `.github/workflows`.
2. Entrar en la pestaña **Actions**.
3. Abrir **Generar IPA de CampusTask sin firma**.
4. Presionar **Run workflow** y seleccionar `main`.
5. Esperar que la ejecución termine en verde.
6. Descargar el artifact `CampusTask-iPhone-sin-firma`.
7. Descomprimirlo para obtener `CampusTask-unsigned.ipa`.
8. Firmarlo e instalarlo con Sideloadly, usando la cuenta secundaria de Apple ya preparada.

El workflow usa XcodeGen para crear `CampusTask.xcodeproj` en el runner macOS y después ejecuta `xcodebuild` para `iphoneos` sin firma. No se deben colocar credenciales de Apple en GitHub.

## Estructura importante

```text
CampusTask/
├── .github/workflows/build-ios-unsigned.yml
├── project.yml
├── CampusTask/
│   ├── App/
│   │   ├── CampusTaskApp.swift
│   │   └── AppState.swift
│   ├── Core/DesignSystem.swift
│   ├── Data/
│   │   ├── APIClient.swift
│   │   ├── DTOs.swift
│   │   ├── KeychainStore.swift
│   │   ├── Models.swift
│   │   └── NetworkMonitor.swift
│   ├── Features/
│   │   ├── DashboardView.swift
│   │   ├── LoginView.swift
│   │   ├── TaskViews.swift
│   │   ├── CoursesView.swift
│   │   ├── SyncStatusView.swift
│   │   └── SettingsView.swift
│   └── Resources/
└── GUIA_EXPOSICION.md
```

## API usada y limitación

El prototipo usa [DummyJSON](https://dummyjson.com/docs) porque ofrece autenticación y endpoints de tareas para pruebas. Sus `POST` y `PATCH` devuelven respuestas HTTP reales, pero la propia documentación aclara que simulan las escrituras y no modifican permanentemente su servidor.

Por eso:

- SwiftData es la fuente persistente de la demostración.
- La cola offline sí se conserva en el iPhone.
- La respuesta de sincronización sirve para demostrar el flujo REST.
- Para producción se reemplazaría `CampusAPI` por un backend persistente sin cambiar las pantallas ni los modelos locales.

## Referencias técnicas

- [Documentación de SwiftData](https://developer.apple.com/documentation/swiftdata)
- [Documentación de URLSession](https://developer.apple.com/documentation/foundation/urlsession)
- [Documentación de Keychain Services](https://developer.apple.com/documentation/security/keychain-services)
- [Documentación de DummyJSON Todos](https://dummyjson.com/docs/todos)
- [Documentación de autenticación de DummyJSON](https://dummyjson.com/docs/auth)

## Aviso

Este proyecto es académico. El flujo de Sideloadly y una cuenta gratuita de Apple es adecuado para pruebas personales; la firma suele expirar a los siete días y no sustituye TestFlight ni la publicación en App Store.
