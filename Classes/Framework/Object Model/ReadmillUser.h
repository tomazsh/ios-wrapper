/*
 Copyright (c) 2011 Readmill LTD
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import "ReadmillAPIWrapper.h"
#import "ReadmillBook.h"

@class ReadmillUser;
@class ReadmillReading;

@protocol ReadmillUserAuthenticationDelegate <NSObject>

/*!
 @param authenticationError An NSError object describing the error. 
 @brief   Delegate method informing the target that the Readmill authentication failed. 
 */
- (void)readmillAuthenticationDidFailWithError:(NSError *)authenticationError;

/*!
 @param loggedInUser A ReadmillUser object, authenticated with Readmill and ready to use. 
 @brief   Delegate method informing the target that the Readmill authentication succeeded. 
 */
- (void)readmillAuthenticationDidSucceedWithLoggedInUser:(ReadmillUser *)loggedInUser;

@end
@protocol ReadmillBookFindingDelegate <NSObject>

/*!
 @param user The user object that was performing the request.
 @param books An array of ReadmillBook objects that matched the given search parameters or were created. 
 @brief   Delegate method informing the target that Readmill found or created the given books. 
 */
- (void)readmillUser:(ReadmillUser *)user didFindBook:(ReadmillBook *)book;

/*!
 @param user The user object that was performing the request.
 @brief   Delegate method informing the target that Readmill could not find any books matching the previously given search criteria. 
 */
- (void)readmillUserFoundNoBook:(ReadmillUser *)user;

/*!
 @param user The user object that was performing the request
 @param error An NSError object describing the error that occurred. 
 @brief   Delegate method informing the target that and error occurred attempting to search for or create book(s). 
 */
- (void)readmillUser:(ReadmillUser *)user failedToFindBookWithError:(NSError *)error;

@end
@protocol ReadmillReadingFindingDelegate <NSObject>

/*!
 @param user The user object that was performing the request.
 @param reading The ReadmillReading objects that matched the given search parameters or were created. 
 @param book The book that the reading were found or created for.
 @brief   Delegate method informing the target that Readmill found or created the given reading.
 */
- (void)readmillUser:(ReadmillUser *)user didFindReading:(ReadmillReading *)reading forBook:(ReadmillBook *)book;

/*!
 @param user The user object that was performing the request.
 @param book The book that the reading(s) were found or created for.
 @brief   Delegate method informing the target that Readmill could not find any reading matching the previously given search criteria and book. 
 */
- (void)readmillUser:(ReadmillUser *)user foundNoReadingForBook:(ReadmillBook *)book;

/*!
 @param user The user object that was performing the request
 @param book The book that the reading(s) were found or created for.
 @param error An NSError object describing the error that occurred. 
 @brief   Delegate method informing the target that and error occurred attempting to search for or create reading(s). 
 */
- (void)readmillUser:(ReadmillUser *)user failedToFindReadingForBook:(ReadmillBook *)book withError:(NSError *)error;

@end
@protocol ReadmillHighlightsFindingDelegate <NSObject>

/*!
 @param user The user object that was performing the request.
 @param highlights An array of retrieved `ReadmillHighlight` objects.
 @param fromDate Beginning date range.
 @param toDate Ending date range.
 @brief Delegate method informing the target that Readmill found highlights.
 */
- (void)readmillUser:(ReadmillUser *)user didFindHighlights:(NSArray *)highlights fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

/*!
 @param user The user object that was performing the request.
 @param fromDate Beginning date range.
 @param toDate Ending date range.
 @param error An NSError object describing the error that occurred.
 @brief Delegate method informing the target that an error occurred attempting to search for highlights.
 */
- (void)readmillUser:(ReadmillUser *)user failedToFindHighlightsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate withError:(NSError *)error;

@end

typedef enum {
    ReadmillUserAvatarSizeSmall,
    ReadmillUserAvatarSizeMedium,
    ReadmillUserAvatarSizeMediumLarge,
    ReadmillUserAvatarSizeLarge
} ReadmillUserAvatarSize;

@interface ReadmillUser : NSObject;

#pragma mark Static Methods

/*!
 @param redirect The URL that Readmill should call upon successful authorization, pass in nil if you want to use the default client redirect URL.
 @param apiConfiguration The API configuration to use.
 @result A URL, appropriate for passing to a web browser, to Readmill to allow authentication.
 @brief   Create a URL for authenticating your application with Readmill.
 
Upon successful authorization, Readmill will call the given redirect URL with added authentication parameters. It's up to 
 you to handle this, but once you've handled the redirect URL you can just pass the whole thing into
 +authenticateCallbackURL:baseCallbackURL:delegate:apiConfiguration: to authenticate. 
 */

+ (NSURL *)clientAuthorizationURLWithRedirectURL:(NSURL *)redirectURL apiConfiguration:(ReadmillAPIConfiguration *)apiConfiguration;


/*!
 @param callbackURL The URL that was called by Readmill.
 @param baseCallbackURL The redirect URL passed into Readmill in +clientAuthorizationURLWithRedirectURL:onStagingServer:.
 @param authenticationDelegate The delegate object to receive notifications of success or failure.
 @param onStaging If true, the authentication will be performed on the Readmill staging server. Normally you'd pass NO. 
 @brief   Authenticate a callback URL from Readmill's authentication service.

 The baseCallbackURL *must* be correct for authentication to succeed, and should be identical to the URL passed into the redirect parameter 
 in +clientAuthorizationURLWithRedirectURL:onStagingServer:.   
 
 For example, let's say your application is set to handle readmillAuth:// URLs and you want to use this as a callback:
 
 NSURL *readmillAuthURL = [ReadmillUser clientAuthorizationURLWithRedirectURL:[NSURL URLWithString:@"readmillAuth://auth"] 
                                                             onStagingServer:NO];
 [[UIApplication sharedApplication] openURL:readmillAuthURL];
 
 This will send the user off to Readmill to authenticate your application. If successful, Readmill will redirect to something like:
 
 readmillAuth://auth?code=xxxxxxxxxxxxx
 
 When you handle this in your application, you need to pass this *and* the original, bare, redirect URL to this method, like this:
 
 NSURL *handledURL = ....; // "readmillAuth://auth?auth_code=xxxxxxxxxxxxx"
 [ReadmillUser authenticateCallbackURL:handledURL baseCallbackURL:[NSURL URLWithString:@"readmillAuth://auth"]  delegate:self onStagingServer:NO];
 
 This will allow the ReadmillUser object to authenticate with Readmill properly.
 */
//+(void)authenticateCallbackURL:(NSURL *)callbackURL baseCallbackURL:(NSURL *)baseCallbackURL delegate:(id <ReadmillUserAuthenticationDelegate>)authenticationDelegate onStagingServer:(BOOL)onStaging;

+ (void)authenticateCallbackURL:(NSURL *)callbackURL baseCallbackURL:(NSURL *)baseCallbackURL delegate:(id <ReadmillUserAuthenticationDelegate>)authenticationDelegate apiConfiguration:(ReadmillAPIConfiguration *)apiConfiguration;

/*!
 @param plistRep The saved credentials.
 @param authenticationDelegate The delegate object to receive notifications of success or failure.
 @brief   Create a user and verify its authentication from saved credentials. 
 
 This is a shortcut for creating a ReadmillUser with -initwithPropertyListRepresentation: then calling -verifyAuthentication: on it. 
 */
+(void)authenticateWithPropertyListRepresentation:(NSDictionary *)plistRep delegate:(id <ReadmillUserAuthenticationDelegate>)authenticationDelegate;

#pragma mark -
#pragma mark Initialization and Serialization

/*!
 @param apiDict An API user dictionary.
 @param wrapper The ReadmillAPIWrapper to be used by the user. 
 @result The created user.
 @brief   Create a new user for the given API user dictionary and wrapper. 
 
 Note: The typical way to obtain a ReadmillUser is to use wither the -initWithPropertyListRepresentation:
 method for saved credentials, or through the static methods +authenticateCallbackURL:baseCallbackURL:delegate:onStagingServer:
 for new authentications or +authenticateWithPropertyListRepresentation:delegate: for existing, saved details.
 
 */
- (id)initWithAPIDictionary:(NSDictionary *)apiDict apiWrapper:(ReadmillAPIWrapper *)wrapper;

/*!
 @paramRep plist The saved credentials.
 @result The created ReadmillUser object.
 @brief   Create a ReadmillUser object with the saved authentication details.
 
 This method will create a ReadmillUser object with the given authentication details
 as obtained through -propertyListRepresentation in a previous session.
 
 IMPORTANT: The saved details will IMMEDIATELY become invalid for use in the future. 
 Best practice would be to remove them from NSUserDefaults (or wherever they same from)
 as soon as you start using the Readmill API, as creating a ReadmillUser object with invalid 
 credentials will break the authentication and starting the authentication process (sending the 
 user to the Readmill site) will be required.
 */
- (id)initWithPropertyListRepresentation:(NSDictionary *)plistRep;

/*!
 @result A set of saved credentials appropriate for storing in NSUserDefaults.
 @brief   Obtain a set of saved credentials appropriate for storing in NSUserDefaults.
 
 The object returned here is appropriate for saving in a property list, NSUserDefaults, or 
 elsewhere, and you can create a new Readmill API object by passing this to 
 -initWithPropertyListRepresentation:.
 
 This value is key-value observing compliant. 
 
 IMPORTANT: These details will change over the course of time. It's very important that you 
 always save the most up-to-date credentials if you plan on using them later, as older 
 credentials become invalid as soon as they're replaced by new ones.
 
 Best practice is to save these to NSUserDefaults every time they change using key-value
 observing, or save them when the application is about to quit.
 
 */
- (NSDictionary *)propertyListRepresentation;

/*!
 @param apiDict An API user dictionary. 
 @brief  Update this user with an NSDictionary from a ReadmillAPIWrapper object.
 
 Typically, there's no need to call this method.
 */
- (void)updateWithAPIDictionary:(NSDictionary *)apiDict;

#pragma mark -
#pragma mark Authentication

/*!
 @param callbackURL The URL that was called by Readmill.
 @param baseCallbackURL The original redirect URL passed into Readmill that originated this request.
 @param authenticationDelegate The delegate object to receive notifications of success or failure.
 @brief   Authenticate a callback URL from Readmill's authentication service.
 
See the documentation for +authenticateCallbackURL:baseCallbackURL:delegate:apiConfiguration: for detailed discussion.
 */
- (void)authenticateCallbackURL:(NSURL *)callbackURL
                baseCallbackURL:(NSURL *)baseCallbackURL
                       delegate:(id <ReadmillUserAuthenticationDelegate>)authenticationDelegate;

/*!
 @param authenticationDelegate The delegate object to receive notifications of success or failure.
 @brief   Verify the authentication credentials of this user with Readmill.
 */
- (void)verifyAuthentication:(id <ReadmillUserAuthenticationDelegate>)authenticationDelegate;

#pragma mark -
#pragma mark Books

/*!
 @param title The title to search for.
 @param author The author to search for.
 @param delegate The delegate object to receive notifications of success or failure.
 @brief   Search for a book in Readmill by title and author. 
 */

- (void)findBookWithTitle:(NSString *)title
                   author:(NSString *)author
                 delegate:(id <ReadmillBookFindingDelegate>)bookfindingDelegate;

/*!
 @param identifierOrNil (optional) The identifier of the book to search for.
 @param author (optional) The author to search for.
 @param title (optional) The title to search for.
 @param delegate The delegate object to receive notifications of success or failure.
 @brief   Search for a book in Readmill by isbn, author and title. 
 */
- (void)findBookWithIdentifier:(NSString *)identifierOrNil
                         title:(NSString *)titleOrNil
                        author:(NSString *)authorOrNil
                      delegate:(id <ReadmillBookFindingDelegate>)bookfindingDelegate;

/*!
 @param isbn The full ISBN of the book to find or create.
 @param title The full title of the book to find or create.
 @param author The full author of the book to find or create.
 @param bookfindingDelegate The delegate object to receive notifications of success or failure.
 @brief   Search for a book in Readmill, creating one if it doesn't exist.
 */
- (void)findOrCreateBookWithIdentifier:(NSString *)identifier
                                 title:(NSString *)title
                                author:(NSString *)author
                              delegate:(id <ReadmillBookFindingDelegate>)bookfindingDelegate;

#pragma mark -
#pragma mark Readings

/*!
 @param book The book to find or create a reading for.
 @param readingState The state of the reading if a new one is created.
 @param isPrivate The privacy of the reading if a new one is created.
 @param readingFindingDelegate The delegate object to receive notifications of success or failure.
 @brief   Find a reading for the given book in Readmill, creating one if it doesn't exist.

 Note: This method returns any existing reading for the particular bookId.
 IMPORTANT: The state and privacy may not match the passed arguments if a reading already existed.
 */
- (void)findOrCreateReadingForBook:(ReadmillBook *)book 
                             state:(ReadmillReadingState)readingState 
                         isPrivate:(BOOL)isPrivate
                          delegate:(id <ReadmillReadingFindingDelegate>)readingFindingDelegate;

/*!
 @param book The book to find or create a reading for.
 @param readingState The state of the reading if a new one is created.
 @param isPrivate The privacy of the reading if a new one is created.
 @param connections (optional) An array consisting of connection IDs (NSString) to post to (unique for user /me/connections/). 
    IMPORTANT: Passing nil connections uses default connections.
 @param readingFindingDelegate The delegate object to receive notifications of success or failure.
 @brief   Find a reading for the given book in Readmill, creating one if it doesn't exist.
 
 Note: This method returns any existing reading for the particular bookId.
 IMPORTANT: The state and privacy may not match the passed arguments if a reading already existed.
*/
- (void)findOrCreateReadingForBook:(ReadmillBook *)book 
                             state:(ReadmillReadingState)readingState
                         isPrivate:(BOOL)isPrivate 
                       connections:(NSArray *)connections
                          delegate:(id <ReadmillReadingFindingDelegate>)delegate;

#pragma mark -
#pragma mark Highlights

- (void)findHighlightsWithCount:(NSUInteger)count
                       fromDate:(NSDate *)fromDate
                         toDate:(NSDate *)toDate
                       delegate:(id <ReadmillHighlightsFindingDelegate>)delegate;


#pragma mark -
#pragma mark - Avatar


- (NSURL *)avatarURLWithSize:(ReadmillUserAvatarSize)size;

#pragma mark -
#pragma mark Properties

/*!
 @property  city
 @brief The city entered into the user's Readmill profile.
 */
@property (readonly, copy) NSString *city;

/*!
 @property  country
 @brief The country entered into the user's Readmill profile.
 */
@property (readonly, copy) NSString *country;

/*!
 @property  userDescription
 @brief The description, or bio, entered into the user's Readmill profile.
 */
@property (readonly, copy) NSString *userDescription;

/*!
 @property  firstName
 @brief The first name entered into the user's Readmill profile.
 */
@property (readonly, copy) NSString *firstName;

/*!
 @property  lastName
 @brief The last name entered into the user's Readmill profile.
 */
@property (readonly, copy) NSString *lastName;

/*!
 @property  fullName
 @brief The full name entered into the user's Readmill profile.
 */
@property (readonly, copy) NSString *fullName;

/*!
 @property  authenticationToken
 @brief The token to be used for direct sign in on the Readmill website
 */
@property (readonly, copy) NSString *authenticationToken;

/*!
 @property  userName
 @brief The user's Readmill username.
 */
@property (readonly, copy) NSString *userName;

/*!
 @property  avatarURL
 @brief The URL of the user's avatar image.
 */
@property (readonly, copy) NSURL *avatarURL;

/*!
 @property  avatarURL
 @brief The URL of the user's avatar image.
 */
@property (readwrite, copy) NSData *avatarImageData;

/*!
 @property  permalinkURL
 @brief The URL of the user's profile on Readmill. Appropriate for linking to the profile in a web browser.
 */
@property (readonly, copy) NSURL *permalinkURL;

/*!
 @property  websiteURL
 @brief The website entered into the user's Readmill profile.
 */
@property (readonly, copy) NSURL *websiteURL;

/*!
 @property  userId
 @brief The Readmill id of the current user.
 */
@property (readonly) ReadmillUserId userId;

/*!
 @property  followerCount
 @brief The number of users that are following the user.
 */
@property (readonly) NSUInteger followerCount;

/*!
 @property  followingCount
 @brief The number of users the user is following.
 */
@property (readonly) NSUInteger followingCount;

/*!
 @property  booksAbandonedCount
 @brief The number of books the user has abandoned.
 */
@property (readonly) NSUInteger booksAbandonedCount;

/*!
 @property  booksFinishedCount
 @brief The number of books the user has completed reading.
 */
@property (readonly) NSUInteger booksFinishedCount;

/*!
 @property  booksInterestingCount
 @brief The number of books the user has marked as interesting.
 */
@property (readonly) NSUInteger booksInterestingCount;

/*!
 @property  booksReadingCount
 @brief The number of books the user is currently reading.
 */
@property (readonly) NSUInteger booksReadingCount;

/*!
 @property  apiWrapper
 @brief The ReadmillAPIWrapper object this user uses.
 */
@property (readonly, retain) ReadmillAPIWrapper *apiWrapper;

@end
