import {Role, AccountStatus} from "@prisma/client";

export interface AuthenticatedUser{
    id: string;
    role: Role;
    firstName: string;
    middleName?: string | null;
    lastName: string;
    email: string;
    status: AccountStatus;
}

declare global {
    namespace Express {
        interface Request {
            user?: AuthenticatedUser;
        }
    }
}