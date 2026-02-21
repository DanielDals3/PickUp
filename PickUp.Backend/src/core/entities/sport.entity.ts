import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'Sports' })
export class Sport {
  @PrimaryGeneratedColumn('increment', { type: 'bigint' })
  id: string;

  @Column({
    type: 'varchar',
    nullable: false,
    default: '',
  })
  name: string;

}