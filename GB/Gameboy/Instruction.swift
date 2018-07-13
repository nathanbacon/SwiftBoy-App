//
//  Instruction.swift
//  GB
//
//  Created by Nathan Gelman on 5/21/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

enum InstType {
    case INC8
    case INC16
    case DEC8
    case DEC16
    
    case RLCA
    case RRCA
    case RLA
    case RRA
    case DAA
    case CPL
    case SCF
    case CCF
    case DI
    case EI
    
    case ADD8
    case ADD16
    case ADC
    case SBC
    case SUB
    case AND
    case XOR
    case OR
    case CP
    case RST
    
    case RLC
    case RRC
    case RL
    case RR
    case SLA
    case SRA
    case SWAP
    case SRL
    case BIT
    case RES
    case SET
    
    case PREFIX
    
    case RET
    case RETI
    case CALL
    
    case POP
    case PUSH
    
    case JP
    case JR
    
    case LD8
    case LD16
    case LDH
    case NOOP
    case STOP
    case HALT
    
    case UNIMPLEMENTED
}

indirect enum Argument {
    case A
    case B
    case C
    case D
    case E
    case H
    case L
    case BC
    case DE
    case HL
    case AF
    case HLi
    case HLd
    case SP
    case SPr8
    case Mem(Argument)
    case Immed8
    case Immed16

    case NZ_flag
    case Z_flag
    case NC_flag
    case C_flag
    
    case Number(UInt8)
}

