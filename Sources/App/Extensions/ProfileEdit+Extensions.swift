import Vapor
import FluentPostgreSQL

// model uses UUID as primary key
extension ProfileEdit: PostgreSQLUUIDModel {}

// model can be passed as HTTP body data
extension ProfileEdit: Content {}

// model can be used as endpoint parameter
extension ProfileEdit: Parameter {}

// MARK: - Custom Migration

extension ProfileEdit: Migration {
    /// Required by `Migration` protocol. Creates the table, with foreign key constraint
    /// to `UserProfile`.
    ///
    /// - Parameter connection: The connection to the database, usually the Request.
    /// - Returns: Void.
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) {
            (builder) in
            try addProperties(to: builder)
            // foreign key contraint to User
            builder.reference(from: \.profileID, to: \UserProfile.id)
        }
    }
}

// MARK: - Timestamping Conformance

extension ProfileEdit {
    /// Required key for `\.createdAt` functionality.
    static var createdAtKey: TimestampKey? { return \.createdAt }
}

// MARK: - Relations

extension ProfileEdit {
    /// The parent `UserProfile` of the edit.
    var profile: Parent<ProfileEdit, UserProfile> {
        return parent(\.profileID)
    }
}
