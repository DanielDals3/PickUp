import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('Countries')
export class Country {
  @PrimaryGeneratedColumn('increment', { type: 'bigint' })
  id: string;

  @Column({
    type: 'varchar',
    nullable: false,
    default: '',
  })
  name: string;

  @Column({
    type: 'varchar',
    nullable: false,
    default: '',
  })
  isoCode: string;

  @Column({
    type: 'varchar',
    nullable: true,
    default: '',
  })
  phone_prefix: string;
}