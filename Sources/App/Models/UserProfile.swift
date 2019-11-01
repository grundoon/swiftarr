import Foundation
import Vapor
import FluentPostgreSQL

/// The optional information provided by a user for their Profile page. The associated
/// `UserProfile` is automatically created wnen a `User` is created via the endpoint. Only
/// the `.userID`, `.username` and `.userSearch` fields are populated upon initialization.

final class UserProfile: Codable {
    // MARK: Properties
    
    /// The profile's ID, provisioned automatically.
    var id: UUID?
    
    /// The `ID` of the parent `User`, provisioned by the creation handler.
    var userID: UUID
    
    /// Concatenation of displayName + (@username) + realName, to speed search by name.
    var userSearch: String
    
    /// The user's username.
    var username: String
    
    /// The filename of the image for the user's profile picture.
    var userImage: String
    
    /// An optional bio or blurb or whatever.
    var about: String?
    
    /// An optional name for display alongside the username. "Display Name (@username)"
    var displayName: String?
    
    /// An optional email address. Social media addresses, URLs, etc. should probably be
    /// in `.about` or maybe `.message`.
    var email: String?
    
    /// An optional home city, country, planet...
    var homeLocation: String?
    
    /// An optional message to anybody viewing the profile. "I like turtles."
    var message: String?
    
    /// An optional preferred pronoun or form of address.
    var preferredPronoun: String?
    
    /// An optional real world name for the user.
    var realName: String?
    
    /// An optional cabin number.
    var roomNumber: String?
    
    /// Limits viewing this profile's info (except `.username` and `.displayName`, which are
    /// always viewable) to logged-in users.
    /// Default is `false`.
    var limitAccess: Bool

    /// Timestamp of the model's creation, set automatically.
    var createdAt: Date?
    
    /// Timestamp of the model's last update, set automatically.
    var updatedAt: Date?
    
    /// Timestamp of the model's soft-deletion, set automatically.
    var deletedAt: Date?

    // MARK: Initialization
    
    ///  Initializes a new UserProfile associated with a `User` account.
    ///
    /// - Parameters:
    ///   - userID: The ID of the parent `User`.
    ///   - username: The .username of the parent `User`.
    ///   - about: An optional nutshell to share publicly.
    ///   - displayName: An optional name for display alongside the username.
    ///   - email: An optional email address to share publicly.
    ///   - homeLocation: An optional home location to share publicly.
    ///   - message: An optional greeting/message to share publicly.
    ///   - preferredPronoun: An optional preferred form of address/reference to share publicly.
    ///   - realName: An optional real name to share publicly.
    ///   - roomNumber: An option cabin number to share publicly.
    ///   - limitAccess: Whether the full version of this profile is only viewable by logged-in users.
    init(
        userID: UUID,
        username: String,
        userImage: String = "",
        about: String? = nil,
        displayName: String? = nil,
        email: String? = nil,
        homeLocation: String? = nil,
        message: String? = nil,
        preferredPronoun: String? = nil,
        realName: String? = nil,
        roomNumber: String? = nil,
        limitAccess: Bool = false
    ) {
        self.userID = userID
        // .userSearch is initially just .username
        self.userSearch = username
        self.userImage = userImage
        self.username = username
        self.about = about
        self.displayName = displayName
        self.email = email
        self.homeLocation = homeLocation
        self.message = message
        self.preferredPronoun = preferredPronoun
        self.realName = realName
        self.roomNumber = roomNumber
        self.limitAccess = limitAccess
    }
    
    // MARK: Codable Representations
    
    /// Used for editing by the owner of the profile.
    final class Private: Codable {
        /// The profile's ID.
        var id: UUID
        /// The user's username.
        var username: String
        /// The filename of the user's profile image.
        var userImage: String
        /// An optional blurb about the user.
        var about: String
        /// An optional name for display alongside the username.
        var displayName: String
        /// An optional email address.
        var email: String
        /// An optional home location (e.g. city)
        var homeLocation: String
        /// An optional greeting/message to visitors of the profile.
        var message: String
        /// An optional preferred form of address.
        var preferredPronoun: String
        /// An optional real name of the user.
        var realName: String
        /// An optional ship cabin number.
        var roomNumber: String
        /// Whether the full profile info should be limited to logged in users.
        var limitAccess: Bool
        
        // MARK: Initialization
        
        /// Initializaes a new UserProfile.Private.
        ///
        /// - Parameters:
        ///   - id: The ID of the profile.
        ///   - username: The user's username.
        ///   - userImage: Filename of the user's profile image.
        ///   - about: A blurb about the user.
        ///   - displayName: A string to display alongside username.
        ///   - email: An email address.
        ///   - homeLocation: The user's home location.
        ///   - message: A greeting/message to users visiting the profile.
        ///   - preferredPronoun: A preferred pronoun or form of address.
        ///   - realName: The user's real name.
        ///   - roomNumber: The user's cabin number.
        ///   - limitAccess: Whether viewing of most profile details is limited to logged in users.
        init(
            id: UUID,
            username: String,
            userImage: String,
            about: String,
            displayName: String,
            email: String,
            homeLocation: String,
            message: String,
            preferredPronoun: String,
            realName: String,
            roomNumber: String,
            limitAccess: Bool
        ) {
            self.id = id
            self.username = username
            self.userImage = userImage
            self.about = about
            self.displayName = displayName
            self.email = email
            self.homeLocation = homeLocation
            self.message = message
            self.preferredPronoun = preferredPronoun
            self.realName = realName
            self.roomNumber = roomNumber
            self.limitAccess = limitAccess
        }
    }

    /// Used for public viewing of the profile.
    ///
    /// A fully populated `.displayedName` property is of the format
    /// "Display Name (@username)", to match how they're seen when posting.
    /// If there is no `.displayName` content, it is simply "@username".
    final class Public: Codable {
        /// The profile's ID.
        var id: UUID
        /// A generated displayName + username string.
        var displayedName: String
        /// Filename of the user's profile image.
        var userImage: String
        /// An optional blurb about the user.
        var about: String
        /// An optional email address for the user.
        var email: String
        /// An optional home location for the user.
        var homeLocation: String
        /// An optional greeting/message to visitors of the profile.
        var message: String
        /// An optional preferred pronoun or form of address.
        var preferredPronoun: String
        /// An optional full name of the user.
        var realName: String
        /// An optional cabin number for the user.
        var roomNumber: String
        /// A `UserNote` owned by the visiting user, about the profile's user (see `UserNote`).
        var note: String?
        
        // MARK: Initialization
        
        /// Creates a new UserProfile.Public.
        ///
        /// - Parameters:
        ///   - id: The ID of the profile.
        ///   - displayName: An optional name for display alongside the username.
        ///   - username: The user's username.
        ///   - userImage: Filename of the user's profile image.
        ///   - about: A blurb about the user.
        ///   - email: An email address for the user.
        ///   - homeLocation: A home location of the user.
        ///   - message: A greeting/message from the user.
        ///   - preferredPronoun: The user's preferred pronoun or form of address.
        ///   - realName: The user's real name.
        ///   - roomNumber: The user's cabin number.
        ///   - note: A note about the user, belonging to the viewer (see `UserNote`).
        init(
            id: UUID,
            displayName: String,
            username: String,
            userImage: String,
            about: String,
            email: String,
            homeLocation: String,
            message: String,
            preferredPronoun: String,
            realName: String,
            roomNumber: String,
            note: String? = nil
        ) {
            self.id = id
            // generate the .displayedName string
            if displayName.isEmpty {
                self.displayedName = "@\(username)"
            } else {
                self.displayedName = displayName + " (@\(username))"
            }
            self.userImage = userImage
            self.about = about
            self.email = email
            self.homeLocation = homeLocation
            self.message = message
            self.preferredPronoun = preferredPronoun
            self.realName = realName
            self.roomNumber = roomNumber
            self.note = note
        }
    }
}

// MARK: - Parent

extension UserProfile {
    /// The parent `User` of the profile.
    var user: Parent<UserProfile, User> {
        return parent(\.userID)
    }
}
