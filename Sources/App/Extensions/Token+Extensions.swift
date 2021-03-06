import Vapor
import FluentPostgreSQL
import Authentication

// model uses UUID as primary key
extension Token: PostgreSQLUUIDModel {}

// model can be passed as HTTP body data
extension Token: Content {}

// MARK: - Custom Migration

extension Token: Migration {
    /// Creates the table, with foreign key constrain to associated `User`.
    ///
    /// - Parameter connection: The connection to the database, usually the Request.
    /// - Returns: Void.
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) {
            builder in
            try addProperties(to: builder)
            // foreign key contraint to User
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

// MARK: - Timestamping Conformance

extension Token {
    /// Required key for `\.createdAt` functionality.
    static var createdAtKey: TimestampKey? { return \.createdAt }
}

// MARK: - Authentication.Token Conformance

extension Token: Authentication.Token {
    /// Required typealias, using `User` class for Authentication.
    typealias UserType = User
    /// Required key for associating UserType to Token.
    static let userIDKey: UserIDKey = \Token.userID
}

// MARK: - BearerAuthenticatable Conformance

extension Token: BearerAuthenticatable {
    /// Required key for HTTP Bearer Authorization token.
    static let tokenKey: TokenKey = \Token.token
}

// MARK: - Methods

extension Token {
    /// Creates a new random Token.
    ///
    /// - Parameter user: The `User` to be associated with this `Token`.
    /// - Parameter length: Desired length of token data, defaults to 16.
    /// - Returns: A `Token` object.
    static func generate(for user: User, length: Int = 16) throws -> Token {
        let random = try CryptoRandom().generateData(count: length)
        return try Token(
            token: random.base64EncodedString(),
            userID: user.requireID()
        )
    }
}

