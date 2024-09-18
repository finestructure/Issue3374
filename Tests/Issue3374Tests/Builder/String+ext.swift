extension String {
    public var pathEncoded: Self {
        replacingOccurrences(of: "/", with: "-")
    }
}
