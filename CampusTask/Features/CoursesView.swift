import SwiftUI
import SwiftData

struct CoursesView: View {
    @Query(sort: \CourseRecord.name) private var courses: [CourseRecord]
    @Query private var tasks: [CampusTaskItem]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(courses, id: \.code) { course in
                        CourseCard(
                            course: course,
                            completed: completedCount(for: course),
                            total: totalCount(for: course)
                        )
                    }
                }
                .padding(18)
            }
            .background(Color.primary.opacity(0.025))
            .navigationTitle("Materias")
        }
    }

    private func totalCount(for course: CourseRecord) -> Int {
        tasks.filter { $0.courseCode == course.code }.count
    }

    private func completedCount(for course: CourseRecord) -> Int {
        tasks.filter { $0.courseCode == course.code && $0.isCompleted }.count
    }
}

private struct CourseCard: View {
    let course: CourseRecord
    let completed: Int
    let total: Int

    private var progress: Double {
        total == 0 ? 0 : Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color(hex: course.colorHex).opacity(0.14))
                        .frame(width: 52, height: 52)
                    Image(systemName: "book.closed.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: course.colorHex))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.name).font(.headline)
                    Text(course.code).font(.caption.bold()).foregroundStyle(Color(hex: course.colorHex))
                }
                Spacer()
            }

            Divider()
            VStack(alignment: .leading, spacing: 7) {
                Label(course.instructor, systemImage: "person.fill")
                Label(course.schedule, systemImage: "calendar")
                Label(course.room, systemImage: "mappin.and.ellipse")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            VStack(spacing: 7) {
                HStack {
                    Text("Progreso").font(.caption.bold())
                    Spacer()
                    Text("\(completed) de \(total)").font(.caption).foregroundStyle(.secondary)
                }
                ProgressView(value: progress)
                    .tint(Color(hex: course.colorHex))
            }
        }
        .campusCard()
    }
}
