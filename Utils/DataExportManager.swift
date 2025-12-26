import Foundation
import SwiftData
import UIKit

@MainActor
class DataExportManager {
    static func generateExportFile(context: ModelContext) -> URL? {
        do {
            // 1. Fetch Data
            let jobs = try context.fetch(FetchDescriptor<Job>(sortBy: [SortDescriptor(\.dateApplied, order: .reverse)]))
            let stories = try context.fetch(FetchDescriptor<Story>())
            let questions = try context.fetch(FetchDescriptor<Question>(sortBy: [SortDescriptor(\.category)]))
            let attempts = try context.fetch(
                FetchDescriptor<PracticeAttempt>(
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
            )
            
            // 2. Build the "Report" String
            var report = """
            INTERVIEW READY - DATA EXPORT
            Generated on: \(Date().formatted(date: .abbreviated, time: .shortened))
            ==================================================
            
            
            """
            
            // --- SECTION: JOBS ---
            report += """
            ### 💼 MY JOBS (\(jobs.count))
            
            """
            
            if jobs.isEmpty {
                report += "(No jobs tracked yet)\n\n"
            } else {
                for job in jobs {
                    report += """
                    • \(job.companyName) - \(job.roleTitle)
                      Stage: \(job.stage.rawValue)
                      Applied: \(job.dateApplied.formatted(date: .numeric, time: .omitted))
                      Notes: \(job.generalNotes.isEmpty ? "None" : job.generalNotes)
                      --------------------------------------------------
                    
                    """
                }
            }
            report += "\n"
            
            // --- SECTION: STORIES ---
            report += """
            ### 📖 MY STAR STORIES (\(stories.count))
            
            """
            
            if stories.isEmpty {
                report += "(No stories recorded yet)\n\n"
            } else {
                for story in stories {
                    report += """
                    • \(story.title)
                      [Situation]: \(story.situation)
                      [Task]: \(story.task)
                      [Action]: \(story.action)
                      [Result]: \(story.result)
                      --------------------------------------------------
                    
                    """
                }
            }
            report += "\n"
            
            // --- SECTION: PRACTICE ANSWERS ---
            let answeredQuestions = questions.filter { $0.isAnswered }
            report += """
            ### 🗣️ PRACTICE ANSWERS (\(answeredQuestions.count))
            
            """
            
            if answeredQuestions.isEmpty {
                report += "(No answers recorded yet)\n"
            } else {
                for q in answeredQuestions {
                    let answeredOnString: String
                    if let answeredDate = q.dateAnswered {
                        answeredOnString = answeredDate.formatted(date: .numeric, time: .omitted)
                    } else {
                        answeredOnString = "N/A"
                    }
                    
                    report += """
                    [Category: \(q.category)]
                    Q: \(q.text)
                    
                    A: \(q.answerText)
                    
                    (Answered on: \(answeredOnString))
                    --------------------------------------------------
                    
                    """
                }
            }
            report += "\n"

            // --- SECTION: PRACTICE ATTEMPTS ---
            report += """
            ### ⏱️ PRACTICE ATTEMPTS (\(attempts.count))

            """

            if attempts.isEmpty {
                report += "(No attempts recorded yet)\n"
            } else {
                for attempt in attempts {
                    let formattedDate = attempt.createdAt.formatted(date: .abbreviated, time: .shortened)
                    report += """
                    • \(formattedDate) — \(attempt.source)
                      Q: \(attempt.questionTextSnapshot)

                    """
                    if let durationSeconds = attempt.durationSeconds {
                        report += "  Duration: \(durationSeconds)s\n"
                    }
                    report += """
                      --------------------------------------------------

                    """
                }
            }
            
            // 3. Save to Temporary File
            let fileName = "InterviewReady_Report.txt"
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try report.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
            
        } catch {
            print("Failed to export data: \(error)")
            return nil
        }
    }
}
