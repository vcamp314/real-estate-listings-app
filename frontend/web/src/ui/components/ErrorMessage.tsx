import React from 'react';
import { useTranslation } from 'react-i18next';
import { AlertCircle } from 'lucide-react';

interface ErrorMessageProps {
    error: string;
}

export const ErrorMessage = ({ error }: ErrorMessageProps) => {
    const { t } = useTranslation();

    return (
        <div className="p-4 mb-6 bg-red-50 border border-red-200 rounded-lg">
            <div className="flex">
                <div className="flex-shrink-0">
                    <AlertCircle className="h-5 w-5 text-red-500" />
                </div>
                <div className="ml-3">
                    <h3 className="text-sm font-medium text-red-800">{t('csvUploader.errors.title')}</h3>
                    <div className="mt-2 text-sm text-red-700">{error}</div>
                </div>
            </div>
        </div>
    );
}; 