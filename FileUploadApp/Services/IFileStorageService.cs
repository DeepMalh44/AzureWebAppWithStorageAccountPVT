namespace FileUploadApp.Services;

public interface IFileStorageService
{
    Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType);
    Task<List<string>> ListFilesAsync();
}
