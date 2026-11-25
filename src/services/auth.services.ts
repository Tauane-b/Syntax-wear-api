import {RegisterRequest} from "../types"
import { prisma } from "../utils/prisma"


export const register = async (payLoad: RegisterRequest) => {
    const existingUsers = await (prisma as any).user.findUnique({
        where: {
            email: payLoad.email
        },
    });
    if (existingUsers) {
        throw new Error("Email já cadastrado");
    }  

    const newUser = await (prisma as any).user.create({
        data: {
            firstName: payLoad.firstName,
            lastName: payLoad.lastName,
            cpf: payLoad.cpf,
            dateofBirth: payLoad.dateofBirth || undefined,
            phone: payLoad.phone,
            email: payLoad.email,
            password: payLoad.password,
            
    
    },
}
);
    return newUser;
}