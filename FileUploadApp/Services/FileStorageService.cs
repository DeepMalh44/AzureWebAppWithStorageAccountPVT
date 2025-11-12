using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace FileUploadApp.Services;

public class FileStorageService : IFileStorageService
{
    private readonly BlobServiceClient _blobServiceClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<FileStorageService> _logger;

    public FileStorageService(
        BlobServiceClient blobServiceClient, 
        IConfiguration configuration,
        ILogger<FileStorageService> logger)
    {
        _blobServiceClient = blobServiceClient;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType)
    {
        try
        {
            var containerName = _configuration["AzureStorage:ContainerName"] ?? "uploads";
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);

            // Create container if it doesn't exist
            await containerClient.CreateIfNotExistsAsync(PublicAccessType.None);

            // Generate unique blob name with timestamp
            var uniqueFileName = $"{DateTime.UtcNow:yyyyMMddHHmmss}_{fileName}";
            var blobClient = containerClient.GetBlobClient(uniqueFileName);

            // Upload the file with metadata
            var blobHttpHeaders = new BlobHttpHeaders
            {
                ContentType = contentType
            };

            await blobClient.UploadAsync(fileStream, new BlobUploadOptions
            {
                HttpHeaders = blobHttpHeaders
            });

            _logger.LogInformation("File {FileName} uploaded successfully to blob storage", uniqueFileName);

            return uniqueFileName;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading file {FileName}", fileName);
            throw;
        }
    }

    public async Task<List<string>> ListFilesAsync()
    {
        try
        {
            var containerName = _configuration["AzureStorage:ContainerName"] ?? "uploads";
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);

            var files = new List<string>();

            if (await containerClient.ExistsAsync())
            {
                await foreach (var blobItem in containerClient.GetBlobsAsync())
                {
                    files.Add(blobItem.Name);
                }
            }

            return files;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error listing files from blob storage");
            throw;
        }
    }
}
