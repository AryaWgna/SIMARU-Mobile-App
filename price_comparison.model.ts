/* eslint-disable @typescript-eslint/no-empty-object-type */
import { Association, DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import Procurement from './procurement.model';
import User from './users.model';

// Enum untuk status perbandingan harga
export enum PriceComparisonStatus {
  DRAFT = 'Draft',
  IN_PROGRESS = 'In Progress',
  COMPLETED = 'Completed'
}

interface PriceComparisonAttributes {
  comparison_id: number;
  comparison_code: string;
  procurement_id: number;
  title: string;
  status: PriceComparisonStatus;
  created_by: number;
  approved_by?: number;
  approved_at?: Date;
  notes?: string;
  created_at?: Date;
  updated_at?: Date;
  deleted_at?: Date;
}

interface PriceComparisonCreationAttributes
  extends Optional<
    PriceComparisonAttributes,
    'comparison_id' | 'comparison_code'
  > {}

class PriceComparison
  extends Model<PriceComparisonAttributes, PriceComparisonCreationAttributes>
  implements PriceComparisonAttributes
{
  public comparison_id!: number;
  public comparison_code!: string;
  public procurement_id!: number;
  public title!: string;
  public status!: PriceComparisonStatus;
  public created_by!: number;
  public approved_by?: number;
  public approved_at?: Date;
  public notes?: string;
  public readonly created_at!: Date;
  public readonly updated_at!: Date;
  public readonly deleted_at?: Date;

  // Deklarasi relasi
  public procurement?: Procurement;
  public creator?: User;
  public approver?: User;

  // Asosiasi model
  public static associations: {
    procurement: Association<PriceComparison, Procurement>;
    creator: Association<PriceComparison, User>;
    approver: Association<PriceComparison, User>;
  };
}

PriceComparison.init(
  {
    comparison_id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
      field: 'id'
    },
    comparison_code: {
      type: DataTypes.STRING(20),
      allowNull: false,
      unique: true
    },
    procurement_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'procurements',
        key: 'id'
      }
    },
    title: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    status: {
      type: DataTypes.ENUM('Draft', 'In Progress', 'Completed'),
      allowNull: false,
      defaultValue: PriceComparisonStatus.DRAFT
    },
    created_by: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'user_id'
      }
    },
    approved_by: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'users',
        key: 'user_id'
      }
    },
    approved_at: {
      type: DataTypes.DATE,
      allowNull: true
    },
    notes: {
      type: DataTypes.TEXT,
      allowNull: true
    }
  },
  {
    sequelize,
    tableName: 'price_comparisons',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    paranoid: true,
    deletedAt: 'deleted_at',
    indexes: [
      {
        unique: true,
        fields: ['comparison_code']
      }
    ]
  }
);

export default PriceComparison; 