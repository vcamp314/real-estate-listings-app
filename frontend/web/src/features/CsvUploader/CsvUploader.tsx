import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Header } from '../../ui/components/Header';
import { ErrorMessage } from '../../ui/components/ErrorMessage';
import { FileUploadForm } from './components/FileUploadForm';
import { Results } from './components/Results';
import { LanguageSwitcher } from '../../ui/components/LanguageSwitcher';
import { API_BASE_URL } from '../../config/api';

interface ApiResponse {
    message: string;
    processed_count: number;
    error_count: number;
    errors?: Array<{
        row: number;
        column: string;
        value: any;
    }>;
}

export const CsvUploader = () => {
    const { t } = useTranslation();
    const [file, setFile] = useState<File | null>(null);
    const [isUploading, setIsUploading] = useState(false);
    const [response, setResponse] = useState<ApiResponse | null>(null);
    const [status, setStatus] = useState<number | null>(null);
    const [error, setError] = useState<string | null>(null);

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const selectedFile = e.target.files?.[0];
        if (selectedFile) {
            // Reset states when selecting a new file
            setFile(selectedFile);
            setResponse(null);
            setStatus(null);
            setError(null);
        }
    };

    const uploadFile = async () => {
        if (!file) return;

        setIsUploading(true);
        setError(null);

        try {
            const formData = new FormData();
            formData.append('file', file);

            const response = await fetch(`${API_BASE_URL}/api/web/v1/rental_listings`, {
                method: 'POST',
                body: formData,
            });

            const statusCode = response.status;
            setStatus(statusCode);

            if ([201, 206, 422].includes(statusCode)) {
                const data = await response.json();
                setResponse(data);
            } else {
                setError(`Error ${statusCode}: ${response.statusText}`);
            }
        } catch (err) {
            setError(t('csvUploader.errors.uploadFailed'));
            console.error('Upload error:', err);
        } finally {
            setIsUploading(false);
        }
    };

    return (
        <div className="flex items-center justify-center min-h-screen bg-gray-50">
            <div className="w-full max-w-4xl mx-auto p-6 bg-white rounded-xl shadow-lg">
                <div className="flex justify-end mb-4">
                    <LanguageSwitcher />
                </div>
                <Header
                    title={t('csvUploader.title')}
                    description={t('csvUploader.description')}
                />

                <FileUploadForm
                    file={file}
                    isUploading={isUploading}
                    onFileChange={handleFileChange}
                    onUpload={uploadFile}
                />

                {error && <ErrorMessage error={error} />}

                {response && status && <Results response={response} status={status} />}
            </div>
        </div>
    );
}; 