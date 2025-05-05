import React from 'react';
import { useTranslation } from 'react-i18next';

interface ErrorTableProps {
    errors: Array<{
        row: number;
        column: string;
        value: any;
    }>;
}

export const ErrorTable = ({ errors }: ErrorTableProps) => {
    const { t } = useTranslation();

    return (
        <div>
            <h4 className="font-medium mb-2">{t('csvUploader.results.validationErrors')}</h4>
            <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-300">
                    <thead className="bg-gray-50">
                        <tr>
                            <th scope="col" className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                {t('csvUploader.results.table.row')}
                            </th>
                            <th scope="col" className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                {t('csvUploader.results.table.column')}
                            </th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                        {errors.map((error, index) => (
                            <tr key={index} className="hover:bg-gray-50">
                                <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{error.row}</td>
                                <td className="px-3 py-2 whitespace-nowrap text-sm font-medium text-gray-900">{error.column}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}; 