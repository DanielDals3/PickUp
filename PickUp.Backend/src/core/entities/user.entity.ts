import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity({ name: 'Users' })
export class User {
  @PrimaryGeneratedColumn('increment', { type: 'bigint' })
  id: string;

  @CreateDateColumn({
    name: 'creation_date',
    type: 'timestamp',
    default: () => 'now()',
  })
  creationDate: Date;

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
  surname: string;

  @Column({
    type: 'varchar',
    nullable: false,
    default: '',
  })
  username: string;

  @Column({
    type: 'varchar',
    nullable: false,
    default: '',
  })
  email: string;

  @Column({
    type: 'date',
    nullable: false,
  })
  birthday: Date;

  @Column({
    type: 'varchar',
    nullable: false,
    default: '',
  })
  password: string;

  @Column({
    type: 'smallint',
    nullable: false,
    default: 0,
  })
  status: number;

  @Column({
    type: 'varchar',
    name: 'avatar_url',
    nullable: true,
  })
  avatarUrl?: string;
}