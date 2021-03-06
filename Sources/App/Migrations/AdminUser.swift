import Vapor
import FluentPostgreSQL
import Crypto

/// A `Migration` that creates the admin user upon startup. The password and recovery key are
/// read from environment variables `ADMIN_PASSWORD` and `RECOVERY_KEY` if present, otherwise
/// defaults are used.
///
/// The defaults are intended and fine for development and testing, but should **never** be
/// used in production. If not set to proper values in `docker-compose.yml` (or whatever
/// other environment of your choice), reminders are printed to console during startup.

struct AdminUser: Migration {
    typealias Database = PostgreSQLDatabase
    
    /// Required by `Migration` protocol. Creates the admin user after a bit of sanity
    /// check caution.
    ///
    /// - Parameter conn: A connection to the database, provided automatically.
    /// - Returns: Void.
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        // retrieve password and recovery key from environment, else use defaults
        let password = Environment.get("ADMIN_PASSWORD") ?? "password"
        let recoveryKey = Environment.get("RECOVERY_KEY") ?? "recovery key"
        
        // default values should never be used in production
        do {
            if (try Environment.detect().isRelease) {
                if password == "password" {
                    print("Please set a proper ADMIN_PASSWORD environment variable.")
                }
                if recoveryKey == "recovery key" {
                    print("Please set a proper RECOVERY_KEY environment variable.")
                }
            }
        } catch let error {
            fatalError("Environment.detect() failed! error: \(error)")
        }
        
        // abort if no sane values or encryption fails
        guard !password.isEmpty, !recoveryKey.isEmpty,
            let passwordHash = try? BCrypt.hash(password),
            let recoveryHash = try? BCrypt.hash(recoveryKey) else {
                fatalError("admin user creation failure: invalid password or recoveryKey")
        }
        
        // create admin user directly
        let user = User(
            username: "admin",
            password: passwordHash,
            recoveryKey: recoveryHash,
            verification: "generated user",
            parentID: nil,
            accessLevel: .admin
        )
        // save user
        return user.save(on: conn).flatMap {
            (savedUser) in
            // ensure we're good to go
            guard let id = savedUser.id else {
                fatalError("admin user creation failure: savedUser.id not found")
            }
            // create default barrels
            var barrels: [Future<Barrel>] = .init()
            let alertKeywordsBarrel = Barrel(
                ownerID: id,
                barrelType: .keywordAlert,
                name: "Alert Keywords"
            )
            alertKeywordsBarrel.userInfo.updateValue([], forKey: "alertWords")
            barrels.append(alertKeywordsBarrel.save(on: conn))
            let blocksBarrel = Barrel(
                ownerID: id,
                barrelType: .userBlock,
                name: "Blocked Users"
            )
            barrels.append(blocksBarrel.save(on: conn))
            let mutesBarrel = Barrel(
                ownerID: id,
                barrelType: .userMute,
                name: "Muted Users"
            )
            barrels.append(mutesBarrel.save(on: conn))
            let muteKeywordsBarrel = Barrel(
                ownerID: id,
                barrelType: .keywordMute,
                name: "Muted Keywords"
            )
            muteKeywordsBarrel.userInfo.updateValue([], forKey: "muteWords")
            barrels.append(muteKeywordsBarrel.save(on: conn))
            // resolve futures, return void
            return barrels.flatten(on: conn).flatMap {
                (savedBarrels) in
                // create associated profile directly
                let profile = UserProfile(userID: id, username: savedUser.username)
                return profile.save(on: conn).transform(to: ())
            }
        }
    }
    
    /// Required by `Migration` protocol, but this isn't a model update, so just return a
    /// pre-completed `Future`.
    ///
    /// - Parameter conn: The database connection.
    /// - Returns: Void.
    static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
        return .done(on: conn)
    }
    
}
