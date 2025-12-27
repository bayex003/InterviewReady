import Foundation
import SwiftData
import UIKit

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case rawText = "Raw Text"

    var id: String { rawValue }
    var title: String { rawValue }
}

@MainActor
class DataExportManager {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func generateExportFiles(
        context: ModelContext,
        jobs: [JobApplication],
        includeStories: Bool,
        includeAttempts: Bool,
        includeJobs: Bool,
        includeQuestions: Bool,
        format: ExportFormat
    ) -> [URL]? {
        do {
            let stories = includeStories ? try context.fetch(FetchDescriptor<Story>(sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)])) : []
            let questions = (includeAttempts || includeQuestions)
                ? try context.fetch(FetchDescriptor<Question>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
                : []
            let attempts = includeAttempts
                ? try context.fetch(FetchDescriptor<PracticeAttempt>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
                : []

            let questionsById = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0) })
            let filteredQuestions = includeQuestions ? questions.filter { $0.isCustom } : []

            let exportDirectory = FileManager.default.temporaryDirectory
                .appendingPathComponent("InterviewReadyExport_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

            switch format {
            case .csv:
                var urls: [URL] = []

                if includeStories {
                    let headers = [
                        "story_id",
                        "title",
                        "tags",
                        "situation",
                        "task",
                        "action",
                        "result",
                        "linked_job_id",
                        "linked_job_title",
                        "updated_at"
                    ]

                    let rows = stories.map { story in
                        [
                            story.id.uuidString,
                            story.title,
                            story.tags.joined(separator: ", "),
                            story.situation,
                            story.task,
                            story.action,
                            story.result,
                            "",
                            "",
                            isoFormatter.string(from: story.lastUpdated)
                        ]
                    }

                    if let url = writeCSV(
                        fileName: "interviewready_stories.csv",
                        headers: headers,
                        rows: rows,
                        to: exportDirectory
                    ) {
                        urls.append(url)
                    }
                }

                if includeAttempts {
                    let headers = [
                        "attempt_id",
                        "timestamp",
                        "duration_seconds",
                        "mode",
                        "question_id",
                        "question_text",
                        "category",
                        "linked_story_id",
                        "linked_story_title",
                        "notes_or_transcript",
                        "rating"
                    ]

                    let rows = attempts.map { attempt in
                        let question = attempt.questionId.flatMap { questionsById[$0] }
                        return [
                            attempt.id.uuidString,
                            isoFormatter.string(from: attempt.createdAt),
                            attempt.durationSeconds.map(String.init) ?? "",
                            attempt.source,
                            attempt.questionId?.uuidString ?? "",
                            attempt.questionTextSnapshot,
                            question?.category ?? "",
                            "",
                            "",
                            attempt.notes ?? "",
                            attempt.confidence.map(String.init) ?? ""
                        ]
                    }

                    if let url = writeCSV(
                        fileName: "interviewready_attempts.csv",
                        headers: headers,
                        rows: rows,
                        to: exportDirectory
                    ) {
                        urls.append(url)
                    }
                }

                if includeJobs {
                    let headers = [
                        "job_id",
                        "company",
                        "role",
                        "location_type",
                        "stage",
                        "next_interview_datetime",
                        "next_interview_notes",
                        "created_at",
                        "linked_story_count"
                    ]

                    let rows = jobs.map { job in
                        [
                            job.id.uuidString,
                            job.companyName,
                            job.roleTitle,
                            job.locationType.rawValue,
                            job.stage.rawValue,
                            job.nextInterviewDate.map { isoFormatter.string(from: $0) } ?? "",
                            job.nextInterviewNotes,
                            isoFormatter.string(from: job.dateApplied),
                            String(job.linkedStoryIDs.count)
                        ]
                    }

                    if let url = writeCSV(
                        fileName: "interviewready_jobs.csv",
                        headers: headers,
                        rows: rows,
                        to: exportDirectory
                    ) {
                        urls.append(url)
                    }
                }

                if includeQuestions {
                    let headers = [
                        "question_id",
                        "question_text",
                        "category",
                        "is_user_created",
                        "linked_story_count"
                    ]

                    let rows = filteredQuestions.map { question in
                        [
                            question.id.uuidString,
                            question.text,
                            question.category,
                            question.isCustom ? "true" : "false",
                            "0"
                        ]
                    }

                    if let url = writeCSV(
                        fileName: "interviewready_questions.csv",
                        headers: headers,
                        rows: rows,
                        to: exportDirectory
                    ) {
                        urls.append(url)
                    }
                }

                return urls.isEmpty ? nil : urls

            case .rawText:
                let exportText = buildRawTextExport(
                    jobs: jobs,
                    stories: stories,
                    attempts: attempts,
                    questions: filteredQuestions,
                    questionsById: questionsById,
                    includeJobs: includeJobs,
                    includeStories: includeStories,
                    includeAttempts: includeAttempts,
                    includeQuestions: includeQuestions
                )

                let fileURL = exportDirectory.appendingPathComponent("interviewready_export.txt")
                try exportText.write(to: fileURL, atomically: true, encoding: .utf8)
                return [fileURL]
            }
        } catch {
            print("Failed to export data: \(error)")
            return nil
        }
    }

    private static func buildRawTextExport(
        jobs: [JobApplication],
        stories: [Story],
        attempts: [PracticeAttempt],
        questions: [Question],
        questionsById: [UUID: Question],
        includeJobs: Bool,
        includeStories: Bool,
        includeAttempts: Bool,
        includeQuestions: Bool
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var output: [String] = []
        output.append("InterviewReady Export")
        output.append("Generated: \(dateFormatter.string(from: Date()))")
        output.append("")

        if includeJobs {
            appendJobsSection(to: &output, jobs: jobs)
        }

        if includeStories {
            appendStoriesSection(to: &output, stories: stories)
        }

        if includeAttempts {
            appendAttemptsSection(to: &output, attempts: attempts, questionsById: questionsById)
        }

        if includeQuestions {
            appendQuestionsSection(to: &output, questions: questions)
        }

        return output.joined(separator: "\n")
    }

    private static func appendJobsSection(to output: inout [String], jobs: [JobApplication]) {
        output.append("JOBS")
        if jobs.isEmpty {
            output.append("No jobs available.")
            output.append("")
            return
        }

        for (index, job) in jobs.enumerated() {
            output.append("\(index + 1))")
            output.append("Company: \(job.companyName)")
            output.append("Role: \(job.roleTitle)")
            output.append("Location Type: \(job.locationType.rawValue)")
            output.append("Stage: \(job.stage.rawValue)")
            let nextInterview = job.nextInterviewDate.map { isoFormatter.string(from: $0) } ?? "None"
            output.append("Next Interview: \(nextInterview)")
            output.append("Next Interview Notes: \(job.nextInterviewNotes.isEmpty ? "None" : job.nextInterviewNotes)")
            output.append("Created: \(isoFormatter.string(from: job.dateApplied))")
            output.append("Linked Stories: \(job.linkedStoryIDs.count)")
            output.append("")
        }
    }

    private static func appendStoriesSection(to output: inout [String], stories: [Story]) {
        output.append("STORIES")
        if stories.isEmpty {
            output.append("No stories available.")
            output.append("")
            return
        }

        for (index, story) in stories.enumerated() {
            output.append("\(index + 1))")
            output.append("Title: \(story.title)")
            output.append("Tags: \(story.tags.joined(separator: ", "))")
            output.append("Situation: \(story.situation)")
            output.append("Task: \(story.task)")
            output.append("Action: \(story.action)")
            output.append("Result: \(story.result)")
            output.append("Linked Job: None")
            output.append("Last Updated: \(isoFormatter.string(from: story.lastUpdated))")
            output.append("")
        }
    }

    private static func appendAttemptsSection(
        to output: inout [String],
        attempts: [PracticeAttempt],
        questionsById: [UUID: Question]
    ) {
        output.append("ATTEMPTS")
        if attempts.isEmpty {
            output.append("No attempts available.")
            output.append("")
            return
        }

        for (index, attempt) in attempts.enumerated() {
            let question = attempt.questionId.flatMap { questionsById[$0] }
            output.append("\(index + 1))")
            output.append("Timestamp: \(isoFormatter.string(from: attempt.createdAt))")
            output.append("Duration Seconds: \(attempt.durationSeconds.map(String.init) ?? "None")")
            output.append("Mode: \(attempt.source)")
            output.append("Question: \(attempt.questionTextSnapshot)")
            output.append("Category: \(question?.category ?? "None")")
            output.append("Linked Story: None")
            output.append("Notes or Transcript: \(attempt.notes ?? "None")")
            output.append("Rating: \(attempt.confidence.map(String.init) ?? "None")")
            output.append("")
        }
    }

    private static func appendQuestionsSection(to output: inout [String], questions: [Question]) {
        output.append("QUESTIONS")
        if questions.isEmpty {
            output.append("No questions available.")
            output.append("")
            return
        }

        for (index, question) in questions.enumerated() {
            output.append("\(index + 1))")
            output.append("Question: \(question.text)")
            output.append("Category: \(question.category)")
            output.append("User Created: \(question.isCustom ? "Yes" : "No")")
            output.append("Linked Stories: 0")
            output.append("")
        }
    }

    private static func writeCSV(
        fileName: String,
        headers: [String],
        rows: [[String]],
        to directory: URL
    ) -> URL? {
        var lines: [String] = []
        lines.append(headers.map(csvEscaped).joined(separator: ","))
        for row in rows {
            lines.append(row.map(csvEscaped).joined(separator: ","))
        }

        let csvString = lines.joined(separator: "\n")
        let fileURL = directory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }

    private static func csvEscaped(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
        let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
        if needsQuotes {
            return "\"\(escapedValue)\""
        }
        return escapedValue
    }
}
