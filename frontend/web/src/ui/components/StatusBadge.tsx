import React from 'react';
import { useTranslation } from 'react-i18next';

interface StatusBadgeProps {
    status: number;
}

export const StatusBadge = ({ status }: StatusBadgeProps) => {
    const { t } = useTranslation();

    const getMessage = () => {
        switch (status) {
            case 201:
                return t('csvUploader.status.success');
            case 206:
                return t('csvUploader.status.warning');
            case 422:
                return t('csvUploader.status.error');
            default:
                return '';
        }
    };

    const badgeStyles = {
        201: 'bg-green-100 text-green-800',
        206: 'bg-amber-100 text-amber-800',
        422: 'bg-red-100 text-red-800'
    }[status] || 'bg-gray-100 text-gray-800';

    return (
        <span className={`text-xs font-normal px-2.5 py-0.5 rounded ${badgeStyles}`}>
            {getMessage()}
        </span>
    );
}; 