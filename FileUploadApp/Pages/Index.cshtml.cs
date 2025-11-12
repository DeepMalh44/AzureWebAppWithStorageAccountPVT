using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using FileUploadApp.Services;
using System.ComponentModel.DataAnnotations;

namespace FileUploadApp.Pages;

public class IndexModel : PageModel
{
    private readonly IFileStorageService _fileStorageService;
    private readonly ILogger<IndexModel> _logger;

    [BindProperty]
    [Required(ErrorMessage = "Please select a file to upload")]
    public IFormFile? UploadedFile { get; set; }

    public string? UploadMessage { get; set; }
    public bool IsSuccess { get; set; }
    public List<string>? UploadedFiles { get; set; }

    public IndexModel(IFileStorageService fileStorageService, ILogger<IndexModel> logger)
    {
        _fileStorageService = fileStorageService;
        _logger = logger;
    }

    public async Task OnGetAsync()
    {
        try
        {
            UploadedFiles = await _fileStorageService.ListFilesAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading uploaded files");
            UploadMessage = "Error loading uploaded files.";
            IsSuccess = false;
        }
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid || UploadedFile == null)
        {
            UploadMessage = "Please select a valid file to upload.";
            IsSuccess = false;
            return Page();
        }

        try
        {
            // Validate file size (max 10MB)
            if (UploadedFile.Length > 10 * 1024 * 1024)
            {
                UploadMessage = "File size must be less than 10MB.";
                IsSuccess = false;
                return Page();
            }

            using var stream = UploadedFile.OpenReadStream();
            var fileName = await _fileStorageService.UploadFileAsync(
                stream, 
                UploadedFile.FileName, 
                UploadedFile.ContentType);

            UploadMessage = $"File '{UploadedFile.FileName}' uploaded successfully!";
            IsSuccess = true;

            // Refresh file list
            UploadedFiles = await _fileStorageService.ListFilesAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading file");
            UploadMessage = "An error occurred while uploading the file. Please try again.";
            IsSuccess = false;
        }

        return Page();
    }
}
