import React from 'react';
import { useTranslation } from 'react-i18next';

export const LanguageSwitcher = () => {
    const { i18n } = useTranslation();

    const changeLanguage = (lng: string) => {
        i18n.changeLanguage(lng);
    };

    return (
        <div className="flex items-center space-x-2">
            <button
                onClick={() => changeLanguage('en')}
                className={`px-3 py-1 rounded ${i18n.language === 'en' ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-700'}`}
            >
                EN
            </button>
            <button
                onClick={() => changeLanguage('ja')}
                className={`px-3 py-1 rounded ${i18n.language === 'ja' ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-700'}`}
            >
                日本語
            </button>
        </div>
    );
}; 