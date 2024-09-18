enum Github {
    struct Repository: Equatable {
        var owner: String
        var name: String

        var path: String { owner + "/" + name }
    }
}
