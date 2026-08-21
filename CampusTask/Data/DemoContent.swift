import Foundation

enum DemoContent {
    static let courses: [CourseDTO] = [
        .init(id: "DSW-401", name: "Desarrollo iOS con Swift", instructor: "Ing. Martínez", room: "Laboratorio 3", colorHex: "6D5DFB", schedule: "Sábado · 8:00 a. m."),
        .init(id: "BD-302", name: "Bases de Datos", instructor: "Ing. Hernández", room: "Aula B-12", colorHex: "0EA5A8", schedule: "Martes · 5:30 p. m."),
        .init(id: "CAL-310", name: "Gestión de Calidad", instructor: "Ing. Ramírez", room: "Aula C-04", colorHex: "F59E0B", schedule: "Jueves · 6:15 p. m."),
        .init(id: "SEG-220", name: "Seguridad Informática", instructor: "Lic. López", room: "Laboratorio 1", colorHex: "EF5DA8", schedule: "Viernes · 4:00 p. m.")
    ]

    static let academicTitles = [
        "Preparar exposición de Swift",
        "Completar práctica de Codable",
        "Diseñar modelo entidad-relación",
        "Estudiar normas ISO 25010",
        "Entregar análisis de riesgos",
        "Crear pruebas de URLSession",
        "Documentar concurrencia con async/await",
        "Revisar proyecto de base de datos",
        "Leer capítulo de seguridad móvil",
        "Subir avance del proyecto final"
    ]

    static let notes = [
        "Incluir una demostración breve y explicar el fragmento de código principal.",
        "Adjuntar capturas y comprobar que los nombres de las propiedades coincidan con el JSON.",
        "Revisar cardinalidades antes de entregar el documento.",
        "Preparar un ejemplo relacionado con calidad de software.",
        "Separar riesgos técnicos, humanos y operativos."
    ]
}
