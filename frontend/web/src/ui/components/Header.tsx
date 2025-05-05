
interface HeaderProps {
    title: string;
    description: string;
}

export const Header = ({ title, description }: HeaderProps) => (
    <div className="mb-8 text-center">
        <h1 className="text-2xl font-bold mb-2">{title}</h1>
        <p className="text-gray-600">{description}</p>
    </div>
); 