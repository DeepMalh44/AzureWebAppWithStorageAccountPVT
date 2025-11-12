using Azure.Storage.Blobs;
using Azure.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly IConfiguration _configuration;
    
    public string? Message { get; set; }
    public bool IsSuccess { get; set; }

    public IndexModel(ILogger<IndexModel> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    public void OnGet()
    {
    }

    public async Task<IActionResult> OnPostAsync(IFormFile file)
    {
        try
        {
            if (file == null || file.Length == 0)
            {
                Message = "Please select a file";
                IsSuccess = false;
                return Page();
            }

            _logger.LogInformation($"Uploading file: {file.FileName}, Size: {file.Length} bytes");

            var storageAccountName = "stfiledevo7bbcldbbn";
            var containerName = "uploads";
            var blobServiceUri = new Uri($"https://{storageAccountName}.blob.core.windows.net");

            // Use only Managed Identity (no fallback to other credential types)
            var blobServiceClient = new BlobServiceClient(blobServiceUri, new ManagedIdentityCredential());
            var containerClient = blobServiceClient.GetBlobContainerClient(containerName);
            
            await containerClient.CreateIfNotExistsAsync();

            var blobName = $"{DateTime.UtcNow:yyyyMMdd_HHmmss}_{file.FileName}";
            var blobClient = containerClient.GetBlobClient(blobName);

            using (var stream = file.OpenReadStream())
            {
                await blobClient.UploadAsync(stream, overwrite: true);
            }

            _logger.LogInformation($"File uploaded successfully: {blobClient.Uri}");
            
            Message = $"File '{file.FileName}' uploaded successfully!";
            IsSuccess = true;
            return Page();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading file");
            Message = $"Error: {ex.Message}";
            IsSuccess = false;
            return Page();
        }
    }
}
