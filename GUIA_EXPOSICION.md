# Guía de exposición de CampusTask

Guion pensado para una demostración de 7 a 10 minutos el sábado 22 de agosto de 2026.

## Antes de entrar al aula

- Abrir CampusTask al menos una vez con internet para dejar tareas guardadas.
- Comprobar que la app abre después de activar modo avión.
- Dejar escritas o memorizadas las credenciales públicas `emilys` / `emilyspass`.
- Reinstalar o volver a firmar la app si la firma gratuita está próxima a vencer.
- Llevar una grabación corta de respaldo por si falla el proyector o la red.
- No cerrar sesión justo antes de presentar: eso elimina el token de Keychain.

## Introducción — 40 segundos

> Buenos días. Para demostrar los temas del capítulo 5 desarrollamos CampusTask, un gestor universitario nativo para iPhone. La aplicación consume una API REST, transforma JSON en modelos Swift y mantiene las tareas disponibles aunque no haya internet. Cuando vuelve la conexión, sincroniza los cambios pendientes. No se trata de cinco ejemplos separados: cada herramienta resuelve una necesidad real de la misma aplicación.

## 1. Inicio de sesión y Keychain — 1 minuto

1. Mostrar la pantalla de acceso.
2. Iniciar sesión con la cuenta pública.
3. Explicar que la API devuelve un token.
4. Ir a **Configuración → Seguridad** y mostrar “Token de sesión protegido”.

Qué decir:

> El tema y los filtros no son datos sensibles y se guardan en UserDefaults. El token permite acceder a la sesión, por eso se guarda en Keychain, que ofrece almacenamiento protegido por el sistema.

Código para mostrar:

- `CampusTask/Data/KeychainStore.swift`, función `saveToken`.
- `CampusTask/Features/SettingsView.swift`, sección “Preferencias · UserDefaults”.

## 2. Concurrencia — 1 minuto

1. En el Dashboard, deslizar hacia abajo para actualizar.
2. Mostrar el mensaje de carga.
3. Abrir **Configuración → Ver temas 5.1–5.5**.

Qué decir:

> En lugar de esperar primero el perfil, después las tareas y por último las materias, usamos tres `async let`. Las operaciones comienzan simultáneamente y la interfaz no se congela. Además, `Task` inicia procesos desde las acciones de SwiftUI.

Código para mostrar:

- `CampusTask/App/AppState.swift`, función `refresh` y comentario “TEMA 5.1”.

## 3. URLSession y Codable — 1 minuto y medio

1. Mostrar las tareas descargadas.
2. Abrir el detalle de una actividad.
3. Crear una nueva actividad con internet.
4. Señalar el mensaje “Tarea enviada con POST”.

Qué decir:

> URLSession ejecuta solicitudes GET, POST y PATCH con async/await. Antes de usar los datos validamos que el código HTTP esté entre 200 y 299. JSONDecoder transforma la respuesta en structs Swift. Usamos CodingKeys porque la API llama `todo` al título, opcionales para campos que pueden faltar y una estrategia para fechas ISO-8601.

Código para mostrar:

- `CampusTask/Data/APIClient.swift`, funciones `send`, `fetchTodos`, `createTodo` y `updateTodo`.
- `CampusTask/Data/DTOs.swift`, modelo `RemoteTodoDTO`.

## 4. SwiftData y trabajo offline — 2 minutos

1. Activar modo avión o apagar Wi-Fi y datos móviles.
2. Volver a CampusTask: las tareas continúan visibles.
3. Crear una tarea nueva o marcar una existente como completada.
4. Abrir **Inicio → icono de nube**.
5. Mostrar el cambio dentro de “Cola local”.

Qué decir:

> La API ya no está disponible, pero SwiftData conserva las tareas, materias y cambios pendientes en el dispositivo. La modificación se refleja de inmediato porque la aplicación trabaja primero con su base local. El estado pendiente indica que todavía no ha llegado al servidor.

Código para mostrar:

- `CampusTask/Data/Models.swift`, clases marcadas con `@Model`.
- `CampusTask/App/AppState.swift`, funciones `createTask`, `toggleCompletion` y `queueCreate`.

## 5. Sincronización al recuperar internet — 1 minuto

1. Reactivar la conexión.
2. Volver a la pantalla de sincronización.
3. Esperar la sincronización automática o presionar **Sincronizar ahora**.
4. Mostrar que la cola queda vacía.

Qué decir:

> NWPathMonitor detecta que regresó la red. Una Task inicia la sincronización; URLSession envía los cambios y, si el servidor responde correctamente, SwiftData elimina cada elemento de la cola. Si ocurre un error, el cambio no se pierde y puede reintentarse.

Código para mostrar:

- `CampusTask/Data/NetworkMonitor.swift`.
- `CampusTask/App/AppState.swift`, función `processPendingChanges`.

## 6. UserDefaults — 40 segundos

1. Entrar en **Configuración**.
2. Cambiar la apariencia a oscuro.
3. Cambiar el filtro inicial.
4. Cerrar y abrir la app para mostrar que la preferencia permanece.

Qué decir:

> UserDefaults es adecuado para preferencias pequeñas y no sensibles. Con `@AppStorage`, SwiftUI actualiza la interfaz automáticamente y conserva el valor entre aperturas.

## Cierre — 25 segundos

> CampusTask demuestra que estas herramientas trabajan juntas: concurrencia para responder más rápido, URLSession para comunicarse, Codable para entender el JSON, Keychain para proteger la sesión, UserDefaults para preferencias y SwiftData para continuar sin conexión. El resultado no es solo una maqueta visual; es un prototipo funcional instalado en un iPhone real.

## Preguntas que podrían hacer

**¿Por qué SwiftData exige iOS 17?**  
Porque Apple introdujo SwiftData en iOS 17. Para versiones anteriores se utilizaría Core Data.

**¿UserDefaults puede guardar el token?**  
Técnicamente puede guardar texto, pero no ofrece la protección adecuada para credenciales. Por eso se usa Keychain.

**¿Qué pasa si una petición devuelve 404 o 500?**  
`CampusAPI.send` valida el código HTTP y lanza un error. El cambio local se conserva para reintentarlo.

**¿POST guarda de verdad la tarea en la API usada?**  
DummyJSON recibe y responde la petición, pero simula la escritura. La persistencia real del prototipo está en SwiftData; en producción se conectaría un backend persistente.

**¿Cuál es la diferencia entre `async let` y `Task`?**  
`async let` inicia operaciones hijas que la función espera y combina. `Task` crea una unidad de trabajo asíncrona, útil para iniciar una acción desde la interfaz.

**¿Cómo evita duplicar tareas?**  
Cada tarea descargada conserva un `serverID` y cada tarea local tiene un `localID` único. Al actualizar, el repositorio busca primero el identificador del servidor.

**¿Qué ocurre si la sincronización falla varias veces?**  
La mutación permanece en SwiftData, aumenta su contador de intentos y conserva el último error para volver a probar.
