namespace SomineApi.WebApi.Security;

public record ClientProofValidationResult(
    bool IsValid,
    string? Error,
    string? ClientId,
    string? Platform
);
