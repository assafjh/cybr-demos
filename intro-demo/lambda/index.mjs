// Node.js 24.x
//cognito-add-app-id-claim
// Authentication Pre Token Generation Lambda Trigger 
// in M2M must be v3

export const handler = async (event) => {
  const clientId = event?.callerContext?.clientId;

  const map = {
    "7j03g529sdski9nde886qac460": "demo-webapp",
  };

  const appId = map[clientId] || "unknown-app";

  event.response ??= {};
  event.response.claimsAndScopeOverrideDetails ??= {};
  event.response.claimsAndScopeOverrideDetails.accessTokenGeneration ??= {};
  event.response.claimsAndScopeOverrideDetails.accessTokenGeneration.claimsToAddOrOverride ??= {};

  event.response.claimsAndScopeOverrideDetails.accessTokenGeneration.claimsToAddOrOverride.app_id = appId;

  return event;
};
