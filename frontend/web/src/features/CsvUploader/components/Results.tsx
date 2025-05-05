import React from 'react';
import { useTranslation } from 'react-i18next';
import { CheckCircle, AlertTriangle, AlertCircle, X } from 'lucide-react';
import { StatusBadge } from '../../../ui/components/StatusBadge';
import { ErrorTable } from './ErrorTable';

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

interface ResultsProps {
    response: ApiResponse;
    status: number;
}

const STATUS_MESSAGES = {
    201: { type: 'success', message: 'All records processed successfully' },
    206: { type: 'warning', message: 'Some records had validation errors' },
    422: { type: 'error', message: 'All records had validation errors' }
};

export const Results = ({ response, status }: ResultsProps) => {
    const { t } = useTranslation();

    // Helper function to render status icon
    const StatusIcon = () => {
        if (status === 201) return <CheckCircle className="h-6 w-6 text-green-500" />;
        if (status === 206) return <AlertTriangle className="h-6 w-6 text-amber-500" />;
        if (status === 422) return <AlertCircle className="h-6 w-6 text-red-500" />;
        return <X className="h-6 w-6 text-red-500" />;
    };

    // Helper function to get color based on status
    const getStatusColor = () => {
        if (status === 201) return 'bg-green-50 border-green-200';
        if (status === 206) return 'bg-amber-50 border-amber-200';
        if (status === 422) return 'bg-red-50 border-red-200';
        return 'bg-red-50 border-red-200';
    };

    return (
        <div className={`p-4 mb-6 border rounded-lg ${getStatusColor()}`}>
            <div className="flex items-start">
                <div className="flex-shrink-0 pt-0.5">
                    <StatusIcon />
                </div>
                <div className="ml-3 w-full">
                    <h3 className="text-sm font-medium text-gray-800 flex items-center justify-between">
                        <span>{t('csvUploader.results.title')}</span>
                        {STATUS_MESSAGES[status as keyof typeof STATUS_MESSAGES] && (
                            <StatusBadge status={status} />
                        )}
                    </h3>

                    <div className="mt-2 text-sm">
                        <div className="mb-4">
                            <p><strong>{t('csvUploader.results.recordsProcessed')}:</strong> {response.processed_count}</p>
                            <p><strong>{t('csvUploader.results.errorCount')}:</strong> {response.error_count}</p>
                        </div>

                        {response.errors && response.errors.length > 0 && (
                            <ErrorTable errors={response.errors} />
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}; 