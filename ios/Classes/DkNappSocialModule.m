/**
 * DkNappSocial
 *
 * Created by Fabian Martinez
 * Copyright (c) 2024 . All rights reserved.
 */

#import "DkNappSocialModule.h"
#import "NappCustomActivity.h"
#import "NappImageProvider.h"
#import "NappItemProvider.h"
#import "TiApp.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiBlob.h"
//include Social and Accounts Frameworks
#import <Accounts/Accounts.h>
#import <Social/Social.h>

#import "TiUIViewProxy.h"
static NSString *const CUSTOM_ACTIVITY = @"custom_activity";

@interface DkNappSocialModule()
@property (nonatomic,readwrite) NSString *ACTIVITY_CUSTOM;
@end

@implementation DkNappSocialModule

#pragma mark Activties

MAKE_SYSTEM_STR(ACTIVITY_FACEBOOK, UIActivityTypePostToFacebook);
MAKE_SYSTEM_STR(ACTIVITY_TWITTER, UIActivityTypePostToTwitter);
MAKE_SYSTEM_STR(ACTIVITY_WEIBO, UIActivityTypePostToWeibo);
MAKE_SYSTEM_STR(ACTIVITY_MESSAGE, UIActivityTypeMessage);
MAKE_SYSTEM_STR(ACTIVITY_MAIL, UIActivityTypeMail);
MAKE_SYSTEM_STR(ACTIVITY_PRINT, UIActivityTypePrint);
MAKE_SYSTEM_STR(ACTIVITY_COPY, UIActivityTypeCopyToPasteboard);
MAKE_SYSTEM_STR(ACTIVITY_ASSIGN_CONTACT, UIActivityTypeAssignToContact);
MAKE_SYSTEM_STR(ACTIVITY_SAVE_CAMERA, UIActivityTypeSaveToCameraRoll);
MAKE_SYSTEM_STR(ACTIVITY_READING_LIST, UIActivityTypeAddToReadingList);
MAKE_SYSTEM_STR(ACTIVITY_FLICKR, UIActivityTypePostToFlickr);
MAKE_SYSTEM_STR(ACTIVITY_VIMEO, UIActivityTypePostToVimeo);
MAKE_SYSTEM_STR(ACTIVITY_AIRDROP, UIActivityTypeAirDrop);
MAKE_SYSTEM_STR(ACTIVITY_TENCENT_WEIBO, UIActivityTypePostToTencentWeibo);
MAKE_SYSTEM_STR(ACTIVITY_OPEN_IN_IBOOKS, UIActivityTypeOpenInIBooks);

// Custom
MAKE_SYSTEM_STR(ACTIVITY_CUSTOM, CUSTOM_ACTIVITY);


#pragma mark Internal

// This is generated for your module, please do not change it
- (id)moduleGUID
{
  return @"7c29d406-9597-4908-af38-2aaad24c61b1";
}

// This is generated for your module, please do not change it
- (NSString *)moduleId
{
  return @"dk.napp.social";
}

#pragma mark Lifecycle

- (void)startup
{
  // This method is called when the module is first loaded
  // You *must* call the superclass
  [super startup];
  self.ACTIVITY_CUSTOM = CUSTOM_ACTIVITY;
  popoverController = nil;
  accountStore = nil;
  DebugLog(@"[DEBUG] %@ loaded", self);
}

#pragma Public APIs


- (BOOL)validateUrl:(NSString *)candidate {
  NSString *urlRegEx = @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
  NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
  return [urlTest evaluateWithObject:candidate];
}

- (NSNumber *)isNetworkSupported:(NSString *)service {
  BOOL available = NO;
  if (NSClassFromString(@"SLComposeViewController")) {
    if ([SLComposeViewController isAvailableForServiceType:service]) {
      available = YES;
    }
  }
  return NUMBOOL(available); //This can call this to let them know if this feature is supported
}

- (NSNumber *)isActivitySupported {
  BOOL available = NO;
  if (NSClassFromString(@"UIActivityViewController")) {
    available = YES;
  }
  return NUMBOOL(available); //This can call this to let them know if this feature is supported
}

- (NSNumber *)isTwitterSupported:(id)args {
  if (NSClassFromString(@"SLComposeViewController") != nil) {
    return [self isNetworkSupported:SLServiceTypeTwitter];
  } else if (NSClassFromString(@"TWTweetComposeViewController") != nil) {
    return NUMBOOL(YES);
  } else {
    return NUMBOOL(NO);
  }
}

- (NSNumber *)isRequestTwitterSupported:(id)args { //for iOS6 twitter
  return [TiUtils isIOSVersionOrGreater:@"6.0"] ? [self isNetworkSupported:SLServiceTypeTwitter] : NUMBOOL(NO);
}

- (NSNumber *)isFacebookSupported:(id)args {
  return [TiUtils isIOSVersionOrGreater:@"6.0"] ? [self isNetworkSupported:SLServiceTypeFacebook] : NUMBOOL(NO);
}

- (NSNumber *)isSinaWeiboSupported:(id)args {
  return [TiUtils isIOSVersionOrGreater:@"6.0"] ? [self isNetworkSupported:SLServiceTypeSinaWeibo] : NUMBOOL(NO);
}

- (NSNumber *)isActivityViewSupported:(id)args {
  return [TiUtils isIOSVersionOrGreater:@"6.0"] ? [self isActivitySupported] : NUMBOOL(NO);
}

- (UIImage *)findImage:(NSString *)imagePath {
  if (imagePath != nil) {
    UIImage *image = nil;

    // Load the image from the application assets
    NSString *fileNamePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:imagePath];
    ;
    image = [UIImage imageWithContentsOfFile:fileNamePath];
    if (image != nil) {
      return image;
    }

    //Load local image by extracting the filename without extension
    NSString *newImagePath = [[imagePath lastPathComponent] stringByDeletingPathExtension];
    image = [UIImage imageNamed:newImagePath];
    if (image != nil) {
      return image;
    }

    //image from URL
    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imagePath]]];
    if (image != nil) {
      return image;
    }

    //load remote image
    image = [UIImage imageWithContentsOfFile:imagePath];
    if (image != nil) {
      return image;
    }
    NSLog(@"image NOT found");
  }
  return nil;
}

/*
 * Accounts
 */
- (void)twitterAccountList:(id)args {
  if (accountStore == nil) {
    accountStore = [[ACAccountStore alloc] init];
  }
  ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

  // request access
  [accountStore requestAccessToAccountsWithType:accountType
                                        options:nil
                                     completion:^(BOOL granted, NSError *error) {
                                       if (granted == YES) {
                                         NSArray *arrayOfAccounts = [accountStore accountsWithAccountType:accountType];

                                         NSMutableArray *accounts = [[NSMutableArray alloc] init];
                                         NSMutableDictionary *dictAccounts = [[NSMutableDictionary alloc] init];
                                         for (NSInteger i = 0; i < [arrayOfAccounts count]; i++) {
                                           ACAccount *account = [arrayOfAccounts objectAtIndex:i];
                                           NSString *userID = [[account valueForKey:@"properties"] valueForKey:@"user_id"];
                                           NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                  userID, @"userId",
                                                                              [NSString stringWithString:account.username], @"username",
                                                                              [NSString stringWithString:account.identifier], @"identifier",
                                                                              nil];
                                           [accounts addObject:dict];
                                         }
                                         [dictAccounts setObject:accounts forKey:@"accounts"];
                                         [self fireEvent:@"accountList" withObject:dictAccounts];

                                       } else {
                                         NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", @"No account", @"status", [error localizedDescription], @"message", @"twitter", @"platform", nil];
                                         [self fireEvent:@"error" withObject:event];
                                       }
                                     }];
}

- (void)shareToNetwork:(NSString *)service args:(id)args {
  ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);

  NSString *platform = nil;

  if (service == SLServiceTypeFacebook) {
    platform = @"facebook";
  }
  if (service == SLServiceTypeTwitter) {
    platform = @"twitter";
  }

  SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:service];
  SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result) {
    if (result == SLComposeViewControllerResultCancelled) {
      NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", platform, @"platform", nil];
      [self fireEvent:@"cancelled" withObject:event];
    } else {
      NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES), @"success", platform, @"platform", nil];
      [self fireEvent:@"complete" withObject:event];
    }
    [controller dismissViewControllerAnimated:YES completion:Nil];
  };
  controller.completionHandler = myBlock;

  //get the properties from javascript
  NSString *shareText = [TiUtils stringValue:@"text" properties:args def:nil];
  NSString *shareUrl = [TiUtils stringValue:@"url" properties:args def:nil];

  //added M Hudson 22/10/14 to allow for blob support
  //see if we passed in a string reference to the file or a TiBlob object

  id TiImageObject = [args objectForKey:@"image"];

  if ([TiImageObject isKindOfClass:[TiBlob class]]) {
    NSLog(@"[INFO] Found an image", nil);
    UIImage *blobImage = [(TiBlob *)TiImageObject image];
    if (blobImage != nil) {
      NSLog(@"[INFO] blob is not null", nil);
      [controller addImage:blobImage];
    }
  } else {
    NSLog(@"[INFO] Think it is a string", nil);
    NSString *shareImage = [TiUtils stringValue:@"image" properties:args def:nil];
    if (shareImage != nil) {
      [controller addImage:[self findImage:shareImage]];
    }
  }

  BOOL animated = [TiUtils boolValue:@"animated" properties:args def:YES];

  if (shareText != nil) {
    [controller setInitialText:shareText];
  }

  if (shareUrl != nil) {
    [controller addURL:[NSURL URLWithString:shareUrl]];
  }

  [[TiApp app] showModalController:controller animated:animated];

  NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:platform, @"platform", nil];
  [self fireEvent:@"dialogOpen" withObject:event];
}

/*
 *  Facebook
 */

- (void)facebook:(id)args {
  ENSURE_UI_THREAD(facebook, args);
  [self shareToNetwork:SLServiceTypeFacebook args:args];
}

- (void)grantFacebookPermissions:(id)args {
  NSDictionary *arguments = [args objectAtIndex:0];

  NSArray *permissionsArray = nil;

  if (accountStore == nil) {
    accountStore = [[ACAccountStore alloc] init];
  }

  ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

  NSString *appId = [arguments objectForKey:@"appIdKey"];
  NSString *permissions = [arguments objectForKey:@"permissionsKey"];

  // Append permissions
  if (permissions != nil) {
    permissionsArray = [permissions componentsSeparatedByString:@","];
  }

  NSDictionary *options = @{
    ACFacebookAppIdKey : appId,
    ACFacebookAudienceKey : ACFacebookAudienceEveryone,
    ACFacebookPermissionsKey : permissionsArray ?: @[]
  };

  // request access
  [accountStore requestAccessToAccountsWithType:accountType
                                        options:options
                                     completion:^(BOOL granted, NSError *error) {
                                       if (granted == YES) {
                                         NSArray *arrayOfAccounts = [accountStore accountsWithAccountType:accountType];

                                         if ([arrayOfAccounts count] > 0) {
                                           ACAccount *fbAccount = [arrayOfAccounts lastObject];

                                           // Get the access token. It could be used in other scenarios
                                           ACAccountCredential *fbCredential = [fbAccount credential];
                                           NSString *accessToken = [fbCredential oauthToken];

                                           NSDictionary *account = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                     [NSString stringWithString:fbAccount.username], @"username",
                                                                                 [NSString stringWithString:fbAccount.identifier], @"identifier",
                                                                                 [NSString stringWithString:accessToken], @"accessToken",
                                                                                 nil];

                                           NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES), @"success", account, @"account", @"facebook", @"platform", nil];
                                           [self fireEvent:@"facebookAccount" withObject:event];

                                         } else {
                                           NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", @"No account", @"status", @"facebook", @"platform", nil];
                                           [self fireEvent:@"error" withObject:event];
                                         }
                                       } else {
                                         NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", @"Permission denied", @"status", [error localizedDescription], @"message", @"facebook", @"platform", nil];
                                         [self fireEvent:@"error" withObject:event];
                                       }
                                     }];
}

- (void)renewFacebookAccessToken:(id)args {
  if (accountStore == nil) {
    accountStore = [[ACAccountStore alloc] init];
  }
  ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
  NSArray *arrayOfAccounts = [accountStore accountsWithAccountType:accountType];
  if ([arrayOfAccounts count] > 0) {
    ACAccount *fbAccount = [arrayOfAccounts lastObject];
    [accountStore renewCredentialsForAccount:fbAccount
                                  completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
                                    if (error) {
                                      NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", @"renew failed", @"status", [error localizedDescription], @"message", @"facebook", @"platform", nil];
                                      [self fireEvent:@"error" withObject:event];
                                    } else {
                                      ACAccountCredential *fbCredential = [fbAccount credential];
                                      NSString *accessToken = [fbCredential oauthToken];
                                      NSDictionary *account = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                [NSString stringWithString:fbAccount.username], @"username",
                                                                            [NSString stringWithString:fbAccount.identifier], @"identifier",
                                                                            [NSString stringWithString:accessToken], @"accessToken",
                                                                            nil];
                                      NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES), @"success", account, @"account", @"facebook", @"platform", nil];
                                      [self fireEvent:@"facebookAccount" withObject:event];
                                    }
                                  }];
  } else {
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", @"No account", @"status", @"facebook", @"platform", nil];
    [self fireEvent:@"error" withObject:event];
  }
}

- (void)requestFacebookWithIdentifier:(id)args {
  NSDictionary *arguments = [args objectAtIndex:0];

  // Defaults
  NSDictionary *requestParameter = nil;
  NSArray *permissionsArray = nil;

  if ([args count] > 1) {
    requestParameter = [args objectAtIndex:1];
  }

  NSString *selectedAccount = [TiUtils stringValue:@"accountWithIdentifier" properties:arguments def:nil];
  NSString *callbackEventName = [TiUtils stringValue:@"callbackEvent" properties:arguments def:@"facebookRequest"];

  if (selectedAccount != nil) {
    //requestType: GET, POST, DELETE
    NSInteger facebookRequestMethod = SLRequestMethodPOST;
    NSString *requestType = [[TiUtils stringValue:@"requestType" properties:arguments def:@"POST"] uppercaseString];

    if ([requestType isEqualToString:@"POST"]) {
      facebookRequestMethod = SLRequestMethodPOST;
    } else if ([requestType isEqualToString:@"GET"]) {
      facebookRequestMethod = SLRequestMethodGET;
    } else if ([requestType isEqualToString:@"DELETE"]) {
      facebookRequestMethod = SLRequestMethodDELETE;
    } else {
      NSLog(@"[Social] no valid request method found - using POST");
    }

    //args
    NSString *requestURL = [arguments objectForKey:@"url"];

    if (requestURL != nil) {
      SLRequest *fbRequest = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:facebookRequestMethod URL:[NSURL URLWithString:requestURL] parameters:requestParameter];
      [fbRequest setAccount:[accountStore accountWithIdentifier:selectedAccount]];
      [fbRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSNumber *isSuccess;

        if ([urlResponse statusCode] == 200) {
          isSuccess = NUMBOOL(YES);
        } else {
          isSuccess = NUMBOOL(NO);
        }

        NSArray *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:isSuccess, @"success", response, @"response", @"facebook", @"platform", nil];
        [self fireEvent:callbackEventName withObject:event];
      }];

    } else {
      NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", @"Missing arguments", @"status", @"facebook", @"platform", nil];
      [self fireEvent:@"error" withObject:event];
    }

  } else {
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", @"Missing arguments", @"status", @"facebook", @"platform", nil];
    [self fireEvent:@"error" withObject:event];
  }
}

- (void)requestFacebook:(id)args {
  NSDictionary *arguments = [args objectAtIndex:0];

  // Defaults
  NSDictionary *requestParameter = nil;
  NSArray *permissionsArray = nil;

  if ([args count] > 1) {
    requestParameter = [args objectAtIndex:1];
  }

  if (accountStore == nil) {
    accountStore = [[ACAccountStore alloc] init];
  }

  ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

  NSString *appId = [arguments objectForKey:@"appIdKey"];
  NSString *permissions = [arguments objectForKey:@"permissionsKey"];
  NSString *callbackEventName = [TiUtils stringValue:@"callbackEvent" properties:arguments def:@"facebookRequest"];

  // Append permissions
  if (permissions != nil) {
    permissionsArray = [permissions componentsSeparatedByString:@","];
  }

  NSDictionary *options = @{
    ACFacebookAppIdKey : appId,
    ACFacebookAudienceKey : ACFacebookAudienceEveryone,
    ACFacebookPermissionsKey : permissionsArray ?: @[]
  };

  [accountStore requestAccessToAccountsWithType:accountType
                                        options:options
                                     completion:^(BOOL granted, NSError *error) {
                                       if (granted) {
                                         NSArray *arrayOfAccounts = [accountStore accountsWithAccountType:accountType];

                                         if ([arrayOfAccounts count] > 0) {
                                           ACAccount *fbAccount = [arrayOfAccounts lastObject];

                                           // Get the access token. It could be used in other scenarios
                                           ACAccountCredential *fbCredential = [fbAccount credential];
                                           NSString *accessToken = [fbCredential oauthToken];

                                           //requestType: GET, POST, DELETE
                                           NSInteger facebookRequestMethod = SLRequestMethodPOST;
                                           NSString *requestType = [[TiUtils stringValue:@"requestType" properties:arguments def:@"POST"] uppercaseString];

                                           if ([requestType isEqualToString:@"POST"]) {
                                             facebookRequestMethod = SLRequestMethodPOST;
                                           } else if ([requestType isEqualToString:@"GET"]) {
                                             facebookRequestMethod = SLRequestMethodGET;
                                           } else if ([requestType isEqualToString:@"DELETE"]) {
                                             facebookRequestMethod = SLRequestMethodDELETE;
                                           } else {
                                             NSLog(@"[Social] no valid request method found - using POST");
                                           }

                                           //args
                                           NSString *requestURL = [arguments objectForKey:@"url"];

                                           if (requestURL != nil) {

                                             SLRequest *fbRequest = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                                                       requestMethod:facebookRequestMethod
                                                                                                 URL:[NSURL URLWithString:requestURL]
                                                                                          parameters:requestParameter];

                                             [fbRequest setAccount:fbAccount];

                                             [fbRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                               NSNumber *isSuccess;

                                               if ([urlResponse statusCode] == 200) {
                                                 isSuccess = NUMBOOL(YES);
                                               } else {
                                                 isSuccess = NUMBOOL(NO);
                                               }

                                               NSArray *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
                                               NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:isSuccess, @"success", response, @"response", accessToken, @"accessToken", @"facebook", @"platform", nil];
                                               [self fireEvent:callbackEventName withObject:event];
                                             }];

                                           } else {
                                             NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", @"Missing arguments", @"status", @"facebook", @"platform", nil];
                                             [self fireEvent:@"error" withObject:event];
                                           }
                                         }
                                       } else {
                                         NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", @"No account", @"status", [error localizedDescription], @"message", @"facebook", @"platform", nil];
                                         [self fireEvent:@"error" withObject:event];
                                       }
                                     }];
}

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
//                  TWITTER API
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

- (void)twitter:(id)args {
  ENSURE_UI_THREAD(twitter, args);

  if (NSClassFromString(@"SLComposeViewController") != nil) {
    [self shareToNetwork:SLServiceTypeTwitter args:args];
  }
}

/**
 * args[0] - requestType, url, accountWithIdentifier
 * args[1] - requestParameter
 *
 */
- (void)requestTwitter:(id)args {
  NSDictionary *arguments = [args objectAtIndex:0];

  // Defaults
  NSDictionary *requestParameter = nil;

  if ([args count] > 1) {
    requestParameter = [args objectAtIndex:1];
  }

  if (accountStore == nil) {
    accountStore = [[ACAccountStore alloc] init];
  }

  ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

  NSString *callbackEventName = [TiUtils stringValue:@"callbackEvent" properties:arguments def:@"twitterRequest"];

  [accountStore requestAccessToAccountsWithType:accountType
                                        options:nil
                                     completion:^(BOOL granted, NSError *error) {
                                       if (granted == YES) {
                                         NSArray *arrayOfAccounts = [accountStore accountsWithAccountType:accountType];

                                         if ([arrayOfAccounts count] > 0) {
                                           NSString *selectedAccount = [TiUtils stringValue:@"accountWithIdentifier" properties:arguments def:nil];
                                           ACAccount *twitterAccount;
                                           if (selectedAccount != nil) {
                                             //user selected
                                             twitterAccount = [accountStore accountWithIdentifier:selectedAccount];
                                             if (twitterAccount == nil) {
                                               //fallback
                                               NSLog(@"[ERROR] Account with identifier does not exist");
                                               twitterAccount = [arrayOfAccounts lastObject];
                                             }
                                           } else {
                                             //use last account in array
                                             twitterAccount = [arrayOfAccounts lastObject];
                                           }

                                           //requestType: GET, POST, DELETE
                                           NSInteger requestMethod = SLRequestMethodPOST;
                                           NSString *requestType = [[TiUtils stringValue:@"requestType" properties:arguments def:@"POST"] uppercaseString];

                                           if ([requestType isEqualToString:@"POST"]) {
                                             requestMethod = SLRequestMethodPOST;
                                           } else if ([requestType isEqualToString:@"GET"]) {
                                             requestMethod = SLRequestMethodGET;
                                           } else if ([requestType isEqualToString:@"DELETE"]) {
                                             requestMethod = SLRequestMethodDELETE;
                                           } else {
                                             NSLog(@"[Social] no valid request method found - using POST");
                                           }

                                           //args
                                           NSString *requestURL = [TiUtils stringValue:@"url" properties:arguments def:nil];

                                           if (requestURL != nil) {

                                             SLRequest *twitterRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                                                            requestMethod:requestMethod
                                                                                                      URL:[NSURL URLWithString:requestURL]
                                                                                               parameters:requestParameter];
                                             [twitterRequest setAccount:twitterAccount];
                                             [twitterRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                               NSNumber *isSuccess;
                                               if ([urlResponse statusCode] == 200) {
                                                 isSuccess = NUMBOOL(YES);
                                               } else {
                                                 isSuccess = NUMBOOL(NO);
                                               }
                                               //NSString *response = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                                               NSArray *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
                                               NSString *rawData = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                                               NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:isSuccess, @"success", response, @"response", rawData, @"rawResponse", @"twitter", @"platform", nil];
                                               
                                               [self fireEvent:callbackEventName withObject:event];
                                             }];

                                           } else {
                                             NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", @"Missing arguments", @"status", @"twitter", @"platform", nil];
                                             [self fireEvent:@"error" withObject:event];
                                           }
                                         }
                                       } else {
                                         NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"success", @"No account", @"status", [error localizedDescription], @"message", @"twitter", @"platform", nil];
                                         [self fireEvent:@"error" withObject:event];
                                       }
                                     }];
}

/*
 *  Sina Weibo
 */

- (void)sinaweibo:(id)args {
  ENSURE_UI_THREAD(sinaweibo, args);
  [self shareToNetwork:SLServiceTypeSinaWeibo args:args];
}

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
//                  UIActivityViewController
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

- (void)activityView:(id)args {
  ENSURE_UI_THREAD(activityView, args);

  NSDictionary *arguments = nil;
  NSArray *customActivities = nil;

  if ([args count] > 1) {
    customActivities = [args objectAtIndex:1];
    arguments = [args objectAtIndex:0];
  } else {
    arguments = [args objectAtIndex:0];
  }

  // Get Properties from JavaScript
  NSString *htmlshareText = [TiUtils stringValue:@"htmlText" properties:arguments def:nil];
  NSString *shareText = [TiUtils stringValue:@"text" properties:arguments def:nil];
  NSURL *shareURL = [NSURL URLWithString:[TiUtils stringValue:@"url" properties:arguments def:nil]];
  NSString *removeIcons = [TiUtils stringValue:@"removeIcons" properties:arguments def:nil];
  NSArray *files = [arguments objectForKey:@"files"];
  // Get custom attributes
  NSString *twitterText = [TiUtils stringValue:@"twitterText" properties:arguments def:nil];
  NSString *twitterImage = [TiUtils stringValue:@"twitterImage" properties:arguments def:nil];
  NSString *facebookImage = [TiUtils stringValue:@"facebookImage" properties:arguments def:nil];

  NSMutableArray *activityItems = [[NSMutableArray alloc] init];

  //added M Hudson 22/10/14 to allow for blob support
  // Image Provider
  id TiImageObject = [arguments objectForKey:@"image"];
  if (TiImageObject != nil) {
    //see if we passed in a string reference to the file or a TiBlob object
    if ([TiImageObject isKindOfClass:[TiBlob class]]) {

      UIImage *image = [(TiBlob *)TiImageObject image];
      if (image) {
        [activityItems addObject:image];
      }

    } else {
      NappImageProvider *shareImageProvider = [[NappImageProvider alloc] initWithPlaceholderItem:@""];

      NSString *shareImage = [TiUtils stringValue:@"image" properties:arguments def:nil];
      shareImageProvider.defaultImage = shareImage;
      shareImageProvider.twitterImage = shareImage;
      shareImageProvider.facebookImage = shareImage;

      if (twitterImage) {
        shareImageProvider.twitterImage = twitterImage;
      }

      if (facebookImage && !shareURL) {
        shareImageProvider.facebookImage = facebookImage;
      } else if (shareURL) {
        shareImageProvider.facebookImage = nil;
      }

      [activityItems addObject:shareImageProvider];
      
    }
  }
  // End Image Provider

  if (shareText) {
    NappItemProvider *textItem = [[NappItemProvider alloc] initWithPlaceholderItem:@""];
    textItem.customText = shareText;
    textItem.customHtmlText = shareText;
    textItem.customTwitterText = shareText;

    if (htmlshareText) {
      textItem.customHtmlText = htmlshareText;
    }

    if (twitterText) {
      textItem.customTwitterText = twitterText;
    }

    [activityItems addObject:textItem];
    
  }

  if (shareURL) {
    [activityItems addObject:shareURL];
  }

  if ([files count] > 0) { 
      for (NSString *theDoc in files) {
           NSURL *fileUrl = [NSURL URLWithString:theDoc];
          [activityItems addObject:fileUrl];
      }
  }  

  UIActivityViewController *avc;

  // Custom Activities
  if (customActivities != nil) {
    NSMutableArray *activities = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < [customActivities count]; i++) {
      NSDictionary *activityDictionary = [customActivities objectAtIndex:i];
      NSString *activityImage = [TiUtils stringValue:@"image" properties:activityDictionary def:nil];
      NSDictionary *activityStyling = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        [TiUtils stringValue:@"type"
                                                                  properties:activityDictionary
                                                                         def:@""],
                                                    @"type",
                                                    [TiUtils stringValue:@"title"
                                                              properties:activityDictionary
                                                                     def:@""],
                                                    @"title",
                                                    [self findImage:activityImage], @"image",
                                                    self, @"module",
                                                    [activityDictionary objectForKey:@"callback"], @"callback",
                                                    nil];

      NappCustomActivity *nappActivity = [[NappCustomActivity alloc] initWithSettings:activityStyling];
      [activities addObject:nappActivity];
      
    }

    avc = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:activities];
    
  } else {
    avc = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
  }

  

  NSString *subject = [TiUtils stringValue:@"subject" properties:arguments def:nil];
  if (subject) {
    [avc setValue:subject forKey:@"subject"];
  }

  // Custom Icons
  if (removeIcons != nil) {
    NSMutableArray *excludedIcons = [self activityIcons:removeIcons];
    [avc setExcludedActivityTypes:excludedIcons];
  }

  // Completion Block Handler
  [avc setCompletionWithItemsHandler:^(UIActivityType _Nullable activityType, BOOL completed, NSArray *_Nullable returnedItems, NSError *_Nullable activityError) {
    if (!completed) {
      NSDictionary *event = @{
        @"success" : @NO,
        @"platform" : @"activityView"
      };
      [self fireEvent:@"cancelled" withObject:event];
    } else {
      // RKS NOTE: Here we must verify if is a CustomActivity or not
      // to returns ACTIVITY_CUSTOM constant
      NSString *activity = activityType;
      if ([activityType rangeOfString:@"com.apple.UIKit.activity"].location == NSNotFound) {
        activity = [self ACTIVITY_CUSTOM];
      }

      NSDictionary *event = @{
        @"success" : @YES,
        @"platform" : @"activityView",
        @"activity" : activity,
        @"activityName" : activityType
      };
      [self fireEvent:@"complete" withObject:event];
    }
  }];

  // Show ActivityViewController
  [[TiApp app] showModalController:avc animated:YES];
}

- (void)activityPopover:(id)args {
  if (![TiUtils isIPad]) {
    NSLog(@"[ERROR] activityPopover is an iPad Only feature");
    return;
  }

  ENSURE_UI_THREAD(activityPopover, args);

  NSDictionary *arguments = nil;
  NSArray *customActivities = nil;
  if ([args count] > 1) {
    customActivities = [args objectAtIndex:1];
    arguments = [args objectAtIndex:0];
  } else {
    arguments = [args objectAtIndex:0];
  }

  if (popoverController.popoverVisible) {
    [popoverController dismissPopoverAnimated:YES];
    return;
  }

  // Get Properties from JavaScript
  NSString *htmlshareText = [TiUtils stringValue:@"htmlText" properties:arguments def:nil];
  NSString *shareText = [TiUtils stringValue:@"text" properties:arguments def:@""];
  NSURL *shareURL = [NSURL URLWithString:[TiUtils stringValue:@"url" properties:arguments def:nil]];
  NSString *removeIcons = [TiUtils stringValue:@"removeIcons" properties:arguments def:nil];
  NSArray *files = [arguments objectForKey:@"files"];
  NSArray *passthroughViews = [arguments objectForKey:@"passthroughViews"];

  BOOL emailIsHTML = [TiUtils boolValue:@"emailIsHTML" properties:arguments def:NO];

  senderButton = [arguments objectForKey:@"view"];

  if (senderButton == nil) {
    NSLog(@"[ERROR] You must specify a source button - property: view");
    return;
  }

  if ([arguments objectForKey:@"rect"]) {
    popoverRect = [TiUtils rectValue:[arguments objectForKey:@"rect"]];
  } else {
    popoverRect = CGRectZero;
  }

  //NSLog(@"[INFO] Button Found", nil);

  //    CGRect rect = [TiUtils rectValue: [(TiUIViewProxy*)senderButton view]];
  //NSLog(@"[INFO] Size: x: %f,y: %f, width: %f, height: %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

  NSMutableArray *activityItems = [[NSMutableArray alloc] init];

  if (shareText) {
    if (emailIsHTML) {
      NappItemProvider *textItem = [[NappItemProvider alloc] initWithPlaceholderItem:@""];
      textItem.customText = shareText;
      textItem.customHtmlText = shareText;
      if (htmlshareText) {
        textItem.customHtmlText = htmlshareText;
      }
      [activityItems addObject:textItem];
      
    } else {
      [activityItems addObject:shareText];
    }
  }

  if (shareURL) {
    [activityItems addObject:shareURL];
  }
  
  if ([files count] > 0) { 
      for (NSString *theDoc in files) {
           NSURL *fileUrl = [NSURL URLWithString:theDoc];
          [activityItems addObject:fileUrl];
      }
  }

  id TiImageObject = [arguments objectForKey:@"image"];
  if (TiImageObject != nil) {
    //see if we passed in a string reference to the file or a TiBlob object
    if ([TiImageObject isKindOfClass:[TiBlob class]]) {

      UIImage *image = [(TiBlob *)TiImageObject image];
      if (image) {
        [activityItems addObject:image];
      }

    } else {

      NSString *shareImage = [TiUtils stringValue:@"image" properties:arguments def:nil];
      if (shareImage != nil) {
        UIImage *image = [self findImage:shareImage];
        if (image) {
          [activityItems addObject:image];
        }
      }
    }
  }

  NSMutableArray *activities = [NSMutableArray array];

  // Custom Activities
  if (customActivities != nil) {
    for (NSInteger i = 0; i < [customActivities count]; i++) {
      NSDictionary *activityDictionary = [customActivities objectAtIndex:i];
      NSString *activityImage = [TiUtils stringValue:@"image" properties:activityDictionary def:nil];
      NSDictionary *activityStyling = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        [TiUtils stringValue:@"type"
                                                                  properties:activityDictionary
                                                                         def:@""],
                                                    @"type",
                                                    [TiUtils stringValue:@"title"
                                                              properties:activityDictionary
                                                                     def:@""],
                                                    @"title",
                                                    [self findImage:activityImage], @"image",
                                                    [activityDictionary objectForKey:@"callback"], @"callback",
                                                    self, @"module",
                                                    nil];

      NappCustomActivity *nappActivity = [[NappCustomActivity alloc] initWithSettings:activityStyling];
      [activities addObject:nappActivity];
      
    }
  }

  UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:activities];
  

  NSString *subject = [TiUtils stringValue:@"subject" properties:arguments def:nil];
  if (subject) {
    [avc setValue:subject forKey:@"subject"];
  }

  // Custom Icons
  if (removeIcons != nil) {
    NSMutableArray *excludedIcons = [self activityIcons:removeIcons];
    [avc setExcludedActivityTypes:excludedIcons];
  }

  // iOS 8 and later should use the item handler instead
  if ([TiUtils isIOSVersionOrGreater:@"8.0"]) {
    [avc setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
      [self fireActivityEventWithActivityType:activityType completed:completed];
      [avc setCompletionWithItemsHandler:nil];
    }];
  } else {
    [avc setCompletionWithItemsHandler:^(UIActivityType _Nullable activityType, BOOL completed, NSArray *_Nullable returnedItems, NSError *_Nullable activityError) {
      [self fireActivityEventWithActivityType:activityType completed:completed];
      [avc setCompletionWithItemsHandler:nil];
    }];
  }

  // popOver
  popoverController = [[UIPopoverController alloc] initWithContentViewController:avc];

  if (passthroughViews != nil) {
    [self setPassthroughViews:passthroughViews];
  }

  TiThreadPerformOnMainThread(^{
    // Button in navigation bar
    if ([senderButton supportsNavBarPositioning] && [senderButton isUsingBarButtonItem]) {
      UIBarButtonItem *item = [senderButton barButtonItem];
      [popoverController presentPopoverFromBarButtonItem:item permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
      return;

      // Button /View inside window
    } else if ([TiUtils isIOSVersionOrGreater:@"8.0"]) {

      // iOS 8 and later
      [avc setModalPresentationStyle:UIModalPresentationPopover];

      viewController = [[TiViewController alloc] initWithViewProxy:senderButton];

      [avc setModalPresentationStyle:UIModalPresentationPopover];
      UIPopoverPresentationController *presentationController = [avc popoverPresentationController];
      presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
      presentationController.delegate = self;

      [[TiApp app] showModalController:avc animated:YES];

    } else {

      // iOS 7 and earlier
      UIView *sourceView = [senderButton view];
      [popoverController presentPopoverFromRect:sourceView.frame inView:[[[TiApp controller] topPresentedController] view] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
  },
      YES);
}

- (void)setPassthroughViews:(id)args {
  NSMutableArray *views = [NSMutableArray arrayWithCapacity:[args count]];
  for (TiViewProxy *proxy in args) {
    if (![proxy isKindOfClass:[TiViewProxy class]]) {
      [self throwException:[NSString stringWithFormat:@"Passed non-view object %@ as passthrough view", proxy] subreason:nil location:CODELOCATION];
    }
    [views addObject:[proxy view]];
  }
  [popoverController setPassthroughViews:views];
}

- (NSMutableArray *)activityIcons:(NSString *)removeIcons {
  NSMutableDictionary *iconMapping = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                                      UIActivityTypePostToTwitter, @"twitter",
                                                                  UIActivityTypePostToFacebook, @"facebook",
                                                                  UIActivityTypeMail, @"mail",
                                                                  UIActivityTypeMessage, @"sms",
                                                                  UIActivityTypeCopyToPasteboard, @"copy",
                                                                  UIActivityTypeAssignToContact, @"contact",
                                                                  UIActivityTypePostToWeibo, @"weibo",
                                                                  UIActivityTypePrint, @"print",
                                                                  UIActivityTypeSaveToCameraRoll, @"camera",
                                                                  UIActivityTypeAddToReadingList, @"readinglist",
                                                                  UIActivityTypePostToFlickr, @"flickr",
                                                                  UIActivityTypePostToVimeo, @"vimeo",
                                                                  UIActivityTypePostToTencentWeibo, @"tencentweibo",
                                                                  UIActivityTypeAirDrop, @"airdrop",
                                                                  UIActivityTypeOpenInIBooks, @"ibooks",
                                                                  nil];

  if ([TiUtils isIOSVersionOrGreater:@"11.0"]) {
    iconMapping[@"pdf"] = UIActivityTypeMarkupAsPDF;
  }

  NSArray *icons = [removeIcons componentsSeparatedByString:@","];
  NSMutableArray *excludedIcons = [[NSMutableArray alloc] init];

  for (NSInteger i = 0; i < [icons count]; i++) {
    NSString *str = [icons objectAtIndex:i];
    [excludedIcons addObject:[iconMapping objectForKey:str]];
  }

  

  return excludedIcons;
}

#pragma mark Helper

- (void)fireActivityEventWithActivityType:(NSString *)activityName completed:(BOOL)completed {
  if (completed == NO) {
    NSDictionary *event = @{
      @"success" : NUMBOOL(NO),
      @"platform" : @"activityPopover",
    };
    [self fireEvent:@"cancelled" withObject:event];
  } else {
    // Here we must verify if is a CustomActivity or not
    // to returns ACTIVITY_CUSTOM constant
    NSString *activity = activityName;
    if ([activityName rangeOfString:@"com.apple.UIKit.activity"].location == NSNotFound) {
      activity = [self ACTIVITY_CUSTOM];
    }

    NSDictionary *event = @{
      @"success" : NUMBOOL(YES),
      @"platform" : @"activityPopover",
      @"activity" : activity,
      @"activityName" : activityName
    };

    [self fireEvent:@"complete" withObject:event];
  }
}

- (NSString *)ACTIVITY_MARKUP_AS_PDF {
  if (![TiUtils isIOSVersionOrGreater:@"11.0"]) {
    return nil;
  }

  return UIActivityTypeMarkupAsPDF;
}

#pragma mark - UIPopoverPresentationController Delegate

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
  NSLog(@"[INFO] prepareForPopoverPresentation");

  if (senderButton != nil) {
    UIView *view = [senderButton view];

    if (view != nil && (view.window != nil)) {

      popoverPresentationController.sourceView = view;
      popoverPresentationController.sourceRect = (CGRectEqualToRect(CGRectZero, popoverRect) ? [view bounds] : popoverRect);
      return;
    }
  }

  //Fell through.
  UIViewController *presentingController = [viewController presentingViewController];
  popoverPresentationController.sourceView = [presentingController view];
  popoverPresentationController.sourceRect = (CGRectEqualToRect(CGRectZero, popoverRect) ? CGRectMake(presentingController.view.bounds.size.width / 2, presentingController.view.bounds.size.height / 2, 1, 1) : popoverRect);
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view {
  NSLog(@"[INFO] popoverPresentationController:willRepositionPopoverToRect");
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
  NSLog(@"[INFO] popoverPresentationControllerDidDismissPopover");
}

@end
