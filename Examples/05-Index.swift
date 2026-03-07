/// # Working with Index & Search
///
/// Create indexes, add records, and perform semantic search.

import aiXplainKit

@main
struct IndexExample {
    static func main() async throws {
        let aix = try Aixplain()

        // --- Create records ---
        let records = [
            Record(text: "Swift is a programming language developed by Apple"),
            Record(text: "Python is widely used for data science and AI"),
            Record(text: "Rust focuses on memory safety and performance"),
            Record(text: "TypeScript adds types to JavaScript"),
        ]
        print("Created \(records.count) records")

        // --- Record with metadata ---
        let taggedRecord = Record(
            text: "Go is a statically typed language from Google",
            attributes: ["category": "languages", "year": "2009"]
        )
        print("Tagged record: \(taggedRecord.value)")
        print("  Attributes: \(taggedRecord.attributes)")

        // --- Build search filters ---
        let filters = IndexFilter.builder()
            .where("category", .equals("languages"))
            .where("year", .greaterThan("2005"))
            .build()
        print("\nFilters: \(filters.map { $0.toDict() })")

        // --- Subscript shorthand ---
        let quickFilter = IndexFilter["language", .contains("en")]
        print("Quick filter: \(quickFilter.toDict())")

        // --- Embedding models ---
        print("\nAvailable embedding models:")
        print("  OpenAI Ada 002: \(EmbeddingModel.openaiAda002.id)")
        print("  BGE-M3: \(EmbeddingModel.bgeM3.id)")
        print("  Multilingual E5: \(EmbeddingModel.multilingualE5Large.id)")

        // --- Work with an existing index ---
        // let index = try await Index.get("your-index-id", context: aix)
        // let results = try await index.search("What is Swift?", topK: 3)
        // for hit in results.hits {
        //     print("  [\(hit.score)] \(hit.data)")
        // }

        // --- Create a new index ---
        // let newIndex = try await Index.create(
        //     name: "Programming Languages",
        //     description: "Knowledge base about programming languages",
        //     embedding: .openaiAda002,
        //     context: aix
        // )
        // try await newIndex.upsert(records)
        // let count = try await newIndex.count()
        // print("Index has \(count) documents")
    }
}
