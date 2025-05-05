import React from 'react';
import { useTranslation } from 'react-i18next';
import { Upload } from 'lucide-react';

interface FileUploadFormProps {
    file: File | null;
    isUploading: boolean;
    onFileChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
    onUpload: () => void;
}

export const FileUploadForm = ({ file, isUploading, onFileChange, onUpload }: FileUploadFormProps) => {
    const { t } = useTranslation();

    return (
        <div className="border border-gray-300 rounded-lg p-6 mb-6">
            <div className="mb-4">
                <label htmlFor="csv-file" className="block text-sm font-medium text-gray-700 mb-2">
                    {t('csvUploader.selectFile')}
                </label>
                <div className="flex items-center">
                    <div className="relative flex-1">
                        <input
                            id="csv-file"
                            type="file"
                            accept=".csv"
                            onChange={onFileChange}
                            className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                        />
                        <div className="flex items-center p-2 text-sm text-gray-900 border border-gray-300 rounded-lg bg-gray-50">
                            <span className="flex-1 truncate">
                                {file ? file.name : t('csvUploader.selectFilePlaceholder')}
                            </span>
                            <Upload className="h-4 w-4 text-gray-500" />
                        </div>
                    </div>
                </div>
            </div>

            <button
                onClick={onUpload}
                disabled={!file || isUploading}
                className={`flex items-center justify-center w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white 
                    ${!file || isUploading ? 'bg-gray-400' : 'bg-blue-600 hover:bg-blue-700'}`}
            >
                {isUploading ?
                    <span className="flex items-center">
                        {t('csvUploader.uploadButton.processing')}
                        <div className="ml-2 w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    </span> :
                    <span className="flex items-center">
                        <Upload className="mr-2 h-4 w-4" />
                        {t('csvUploader.uploadButton.default')}
                    </span>
                }
            </button>
        </div>
    );
}; 