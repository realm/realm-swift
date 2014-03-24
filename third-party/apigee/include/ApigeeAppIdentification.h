//
//  ApigeeAppIdentification.h
//  ApigeeiOSSDK
//
//  Copyright (c) 2013 Apigee. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class ApigeeAppIdentification
 @abstract The ApigeeAppIdentification class contains various fields that are
    used by the application when talking with the server
 */
@interface ApigeeAppIdentification : NSObject
{
    NSString* _organizationId;
    NSString* _applicationId;
    NSString* _organizationUUID;
    NSString* _applicationUUID;
    NSString* _baseURL;
}

/*!
 @property organizationId
 @abstract The identifier used by Apigee to uniquely identify the organization
 */
@property (copy,nonatomic) NSString* organizationId;

/*!
 @property applicationId
 @abstract The identifier used by Apigee to uniquely identify the application
 */
@property (copy,nonatomic) NSString* applicationId;

/*!
 @property organizationUUID
 @abstract The UUID used by Apigee to uniquely identify the organization
 */
@property (copy,nonatomic) NSString* organizationUUID;

/*!
 @property applicationUUID
 @abstract The UUID used by Apigee to uniquely identify the application
 */
@property (copy,nonatomic) NSString* applicationUUID;

/*!
 @property baseURL
 @abstract The URL used for server communications
 */
@property (copy,nonatomic) NSString* baseURL;


/*!
 @abstract Initializes an ApigeeAppIdentification instance using identifier
    values for organization and application
 @param organizationId the identifier for the organization
 @param applicationId the identifier for the application
 */
- (id)initWithOrganizationId:(NSString*)organizationId
               applicationId:(NSString*)applicationId;

/*!
 @abstract Initializes an ApigeeAppIdentification instance using UUID values
    for organization and application
 @param organizationUUID the UUID for the organization
 @param applicationUUID the UUID for the application
 */
- (id)initWithOrganizationUUID:(NSString*)organizationUUID
               applicationUUID:(NSString*)applicationUUID;

/*!
 @abstract Retrieves unique identifier for app within org
 @return unique identifier as string
 */
- (NSString*)uniqueIdentifier;

@end
