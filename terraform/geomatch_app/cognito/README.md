# Cognito Module

This module sets up an AWS Cognito User Pool with various configurations and outputs. It is designed to integrate with external identity providers, including Stanford iDP, which is typically configured by default to require encryption. However, this terraform module does not do a great job of enabling encryption by default. Users will need to manually enable the checkboxes for "Sign SAML requests to this provider" and "Require encrypted SAML assertions from this provider." using AWS Console to accomplish the same.

## Cognito Module Variables

- **project**: (string) The name of the project.
- **environment**: (string) The environment (e.g., dev, prod).
- **aws_region**: (string) The AWS region where resources are created.
- **ecr_name_suffix**: (string) Default is "app". Suffix for the ECR name.
- **idp_metadata_url**: (string) Default is "app". Metadata URL for the identity provider, e.g. https://login.stanford.edu/metadata.xml.
- **ssm_name_prefix**: (string) Should be '/{project}/{environment}'.
- **cognito_region**: (string) The region where the user pool is created.
- **cognito_redirect_uri**: (list of strings) The redirect URI of the user pool, first element contains the relevant uri.
- **cognito_email_verification_message**: (string) Email verification message.
- **cognito_email_verification_subject**: (string) Email verification subject.
- **cognito_admin_create_user_message**: (string) Admin create user message.
- **cognito_admin_create_user_subject**: (string) Admin create user subject.
- **cognito_allow_email_address**: (string) Allow email address for Cognito.
- **subdomain**: (string) Subdomain for the application (e.g., 'us').
- **domain**: (string) The domain for the Cognito callback URLs.
- **external_providers**: (list of objects) List of external identity providers to be added to the Cognito user pool. Each object includes:
  - **provider_name**: (string) Name of the provider.
  - **provider_type**: (string) Type of the provider.
  - **metadata_url**: (string) Metadata URL for the provider.
  - **attribute_mapping**: (map of strings) Attribute mapping for the provider.
  - **identifiers**: (list of strings) Identifiers for the provider.
  - **sign_out_flow**: (bool) Whether to use sign out flow.
  - **sign_saml_requests**: (bool) Whether to sign SAML requests.
  - **require_encrypted_assertions**: (bool) Whether to require encrypted assertions.

## Outputs

- **cognito_region**: The AWS region where Cognito resources are created.
- **cognito_client_id**: The Cognito User Pool Client ID.
- **cognito_user_pool_id**: The Cognito User Pool ID.
- **cognito_client_secret**: The Cognito User Pool Client Secret (sensitive).
- **cognito_redirect_uri**: The Cognito redirect URI.
- **cognito_app_domain**: The Cognito app domain.
- **cognito_authorization_endpoint**: The Cognito authorization endpoint.
- **cognito_token_url**: The Cognito token get endpoint.
- **cognito_user_pool_arn**: The Cognito User Pool ARN.

## Configuration Notes

- **Stanford iDP Configuration**: Please refer to the additional resources section as well as notes on the top for configuring Stanford iDP.

## Resources

### User Pool

The module creates an AWS Cognito User Pool with the following configurations:

### User Pool Client

### User Pool Domain

### Identity Provider

The module supports external identity providers with the following configurations:

- **User Pool ID**: Associated with the created user pool.
- **Provider Name and Type**: Configurable for each provider.
- **Provider Details**: Includes metadata URL and sign-out flow settings.
- **Attribute Mapping**: Configurable mapping for user attributes.
- **IDP Identifiers**: Configurable identifiers for the identity provider.

## Additional Resources

For more information on integrating with Stanford's SAML service, you can refer to the following resources:

- [Onboarding a Service Provider with Stanford SAML](https://uit.stanford.edu/service/saml/onboard-service-provider)
- [Stanford SAML Exception Handling](https://uit.stanford.edu/service/saml/exception)
- [Stanford FarmFed SAML Service](https://uit.stanford.edu/service/saml/farmfed)
- [SPDB Management Portal](https://spdb-prod.iam.stanford.edu/spconfigs)

### Authentication Flow

Here's how the authentication flow works:

1. The user accesses your application through the ALB (Application Load Balancer).
2. The ALB initiates authentication with Cognito.
3. Cognito redirects the user to Stanford IdP for authentication.
4. After successful authentication, Stanford IdP sends a SAML assertion back to Cognito.
5. Cognito processes the SAML assertion and redirects back to the ALB.
6. The ALB forwards the authenticated request to the target group.
7. The target group routes the request to your AWS Lambda function.

### Implementation Steps

To implement this flow:

- Configure your ALB listener rule to use Cognito for authentication.
- Set up your Cognito User Pool with Stanford University as a SAML identity provider.
- Configure the callback URL in your Cognito User Pool client settings to point to your ALB: `https://your-alb-dns/oauth2/idpresponse`.
- Ensure your Stanford IdP is correctly set up to send SAML assertions to Cognito.
- Configure your ALB to forward authenticated requests to your target group containing the Lambda function.