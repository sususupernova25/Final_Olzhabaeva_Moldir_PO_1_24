drop schema if exists driving_school cascade;
create schema driving_school;
set search_path to driving_school;

create table if not exists driving_school.categories (
    category_id     serial          primary key,
    category_code   varchar(5)      not null unique,
    description     varchar(100),
    base_price      numeric(10,2)   not null check (base_price > 0),
    training_hours  int             not null check (training_hours > 0)
);
 
create table if not exists driving_school.branches (
    branch_id      serial        primary key,
    branch_name    varchar(50)   not null,
    address        varchar(250)  not null,
    phone          varchar(20)   not null,
    contact_email  varchar(100)
);
 
create table if not exists driving_school.instructors (
    instructor_id   serial        primary key,
    branch_id       int           not null,
    full_name       varchar(100)  not null,
    license_number  varchar(50)   not null unique,
    email           varchar(100)  not null unique,
    phone           varchar(20)   not null unique,
    foreign key (branch_id) references driving_school.branches(branch_id) on delete restrict
);
 
create table if not exists driving_school.vehicles (
    vehicle_id        serial       primary key,
    plate_number      varchar(15)  not null unique,
    model             varchar(50)  not null,
    manufacture_year  int,
    transmission      varchar(20)  not null check (transmission in ('manual', 'automatic')),
    status            varchar(20)  default 'active'
);
 
create table if not exists driving_school.students (
    student_id       serial        primary key,
    branch_id        int           not null,
    category_id      int           not null,
    full_name        varchar(100)  not null,
    email            varchar(100)  not null unique,
    phone            varchar(20)   not null unique,
    enrollment_date  date          not null check (enrollment_date > date '2026-01-01'),
    status           varchar(20)   default 'enrolled',
    is_vip           boolean       default false,
    foreign key (branch_id)   references driving_school.branches(branch_id)     on delete restrict,
    foreign key (category_id) references driving_school.categories(category_id) on delete restrict
);
 
create table if not exists driving_school.salary (
    salary_id          serial         primary key,
    instructor_id      int            not null,
    payment_date       date           not null,
    calculated_amount  numeric(10,2)  not null check (calculated_amount > 0),
    salary_month       date           not null check (salary_month > date '2026-01-01'),
    is_paid            boolean        default false,
    foreign key (instructor_id) references driving_school.instructors(instructor_id) on delete restrict
);
 
create table if not exists driving_school.lessons (
    lesson_id      serial         primary key,
    instructor_id  int            not null,
    vehicle_id     int            not null,
    student_id     int            not null,
    lesson_date    date           not null check (lesson_date > date '2026-01-01'),
    duration_hours int            not null check (duration_hours > 0),
    hourly_rate    numeric(10,2)  default 40.00 check (hourly_rate >= 0),
    total_price    numeric(10,2)  generated always as (duration_hours * hourly_rate) stored,
    lesson_status  varchar(20)    default 'scheduled',
    check (lesson_status in ('scheduled', 'completed', 'cancelled')),
    foreign key (instructor_id) references driving_school.instructors(instructor_id) on delete restrict,
    foreign key (vehicle_id)    references driving_school.vehicles(vehicle_id)       on delete restrict,
    foreign key (student_id)    references driving_school.students(student_id)       on delete cascade
);
 
create table if not exists driving_school.payments (
    payment_id    serial         primary key,
    student_id    int            not null,
    amount        numeric(10,2)  not null check (amount > 0),
    payment_date  date           default current_date,
    foreign key (student_id) references driving_school.students(student_id) on delete cascade
);
 
-- junction table
create table if not exists driving_school.attendance (
    attendance_id    serial        primary key,
    student_id       int           not null,
    lesson_id        int           not null,
    student_present  boolean       default true,
    notes            varchar(255),
    foreign key (student_id) references driving_school.students(student_id) on delete cascade,
    foreign key (lesson_id)  references driving_school.lessons(lesson_id)   on delete cascade
);
 
create table if not exists driving_school.exams (
    exam_id     serial        primary key,
    student_id  int           not null,
    exam_type   varchar(20)   not null check (exam_type in ('theoretical', 'practical')),
    exam_date   date          not null check (exam_date > date '2026-01-01'),
    score       int           not null check (score between 0 and 100),
    is_passed   boolean       default false,
    notes       varchar(255),
    foreign key (student_id) references driving_school.students(student_id) on delete cascade
);
 
 
alter table driving_school.branches
    alter column phone type varchar(25);
 
alter table driving_school.branches
    add constraint uq_branch_name unique (branch_name);
 
alter table driving_school.students
    rename column is_vip to is_premium;
 
alter table driving_school.students
    add column drop_reason varchar(255);
 
alter table driving_school.vehicles
    alter column status set default 'active';
 
alter table driving_school.branches
    add constraint uq_branch_email unique (contact_email);
 
 
truncate table
    driving_school.attendance,
    driving_school.exams,
    driving_school.payments,
    driving_school.lessons,
    driving_school.salary,
    driving_school.students,
    driving_school.instructors,
    driving_school.vehicles,
    driving_school.branches,
    driving_school.categories
restart identity cascade;
 
-- categories
insert into driving_school.categories (category_code, description, base_price, training_hours) values
    ('A',  'Motorcycle license',        150000.00, 20),
    ('B',  'Passenger car license',     200000.00, 30),
    ('C',  'Truck license',             250000.00, 40),
    ('D',  'Bus license',               300000.00, 50),
    ('BE', 'Car with trailer license',  220000.00, 35);
 
-- branches
insert into driving_school.branches (branch_name, address, phone, contact_email) values
    ('Atyrau Central',  '12 Satpaev St, Atyrau',        '+77122345671', 'atyrau.central@drivingschool.kz'),
    ('Atyrau North',    '5 Aiteke Bi Ave, Atyrau',      '+77122345672', 'atyrau.north@drivingschool.kz'),
    ('Almaty Main',     '15 Abay Ave, Almaty',           '+77272345673', 'almaty.main@drivingschool.kz'),
    ('Astana Central',  '10 Mangilik El Ave, Astana',    '+77172345674', 'astana.central@drivingschool.kz'),
    ('Shymkent Branch', '7 Tauke Khan Ave, Shymkent',    '+77252345675', 'shymkent@drivingschool.kz');
 
-- instructors 
insert into driving_school.instructors (branch_id, full_name, license_number, email, phone) values
    (
        (select branch_id from driving_school.branches where branch_name = 'Atyrau Central'),
        'Нурланов Бекзат Серикович', 'LIC-2024-001', 'bekzat.n@drivingschool.kz', '+77011110001'
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Atyrau Central'),
        'Сейткали Айдар Маратович', 'LIC-2024-002', 'aidar.s@drivingschool.kz', '+77011110002'
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Atyrau North'),
        'Жаксыбеков Ерлан Болатович', 'LIC-2024-003', 'erlan.zh@drivingschool.kz', '+77011110003'
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Almaty Main'),
        'Ахметов Дамир Русланович', 'LIC-2024-004', 'damir.a@drivingschool.kz', '+77011110004'
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Astana Central'),
        'Оспанов Асхат Кайратович', 'LIC-2024-005', 'askhat.o@drivingschool.kz', '+77011110005'
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Shymkent Branch'),
        'Тулегенов Санжар Маратович', 'LIC-2024-006', 'sanzhar.t@drivingschool.kz', '+77011110006'
    );
 
-- vehicles
insert into driving_school.vehicles (plate_number, model, manufacture_year, transmission, status) values
    ('077 AA 01', 'Toyota Corolla',   2022, 'automatic', 'active'),
    ('077 AB 01', 'Hyundai Accent',   2021, 'manual',    'active'),
    ('077 AC 01', 'Kia Rio',          2023, 'automatic', 'active'),
    ('077 AD 01', 'Chevrolet Nexia',  2020, 'manual',    'active'),
    ('077 AE 01', 'Lada Vesta',       2022, 'manual',    'active'),
    ('077 AF 01', 'Toyota Camry',     2023, 'automatic', 'active'),
    ('077 AG 01', 'Honda Civic',      2021, 'manual',    'maintenance');
 
-- students
insert into driving_school.students (branch_id, category_id, full_name, email, phone, enrollment_date, status, is_premium) values
    (
        (select branch_id from driving_school.branches where branch_name = 'Atyrau Central'),
        (select category_id from driving_school.categories where category_code = 'B'),
        'Олжабаева Молдир', 'moldyr.olzhabayeva@gmail.com', '+77021110001', '2026-02-01', 'enrolled', false
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Atyrau Central'),
        (select category_id from driving_school.categories where category_code = 'B'),
        'Жумакулова Асылай', 'assylai.zhumakulova@gmail.com', '+77021110002', '2026-02-03', 'enrolled', true
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Atyrau North'),
        (select category_id from driving_school.categories where category_code = 'A'),
        'Хисметова Аружан', 'aruzhan.khismetova@gmail.com', '+77021110003', '2026-02-05', 'enrolled', false
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Atyrau North'),
        (select category_id from driving_school.categories where category_code = 'B'),
        'Амиржанкызы Асылай', 'assylai.amirzhankyz@gmail.com', '+77021110004', '2026-02-10', 'enrolled', false
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Almaty Main'),
        (select category_id from driving_school.categories where category_code = 'B'),
        'Кайракбай Инабат', 'inabat.kairakbay@gmail.com', '+77021110005', '2026-02-15', 'enrolled', true
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Almaty Main'),
        (select category_id from driving_school.categories where category_code = 'C'),
        'Балгабай Асель', 'assel.balgabay@gmail.com', '+77021110006', '2026-03-01', 'enrolled', false
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Astana Central'),
        (select category_id from driving_school.categories where category_code = 'B'),
        'Аманбай Айкен', 'aiken.amanbay@gmail.com', '+77021110007', '2026-03-05', 'enrolled', false
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Astana Central'),
        (select category_id from driving_school.categories where category_code = 'D'),
        'Жумагали Айша', 'aisha.zhumagali@gmail.com', '+77021110008', '2026-03-10', 'enrolled', false
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Shymkent Branch'),
        (select category_id from driving_school.categories where category_code = 'B'),
        'Шахмет Актоты', 'aktoty.shakhmet@gmail.com', '+77021110009', '2026-03-15', 'enrolled', true
    ),
    (
        (select branch_id from driving_school.branches where branch_name = 'Shymkent Branch'),
        (select category_id from driving_school.categories where category_code = 'BE'),
        'Сахташова Райхан', 'raikhan.sakhtashova@gmail.com', '+77021110010', '2026-03-20', 'enrolled', false
    );
 
-- salary records
insert into driving_school.salary (instructor_id, payment_date, calculated_amount, salary_month, is_paid) values
    (
        (select instructor_id from driving_school.instructors where email = 'bekzat.n@drivingschool.kz'),
        '2026-02-28', 350000.00, '2026-02-01', true
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'aidar.s@drivingschool.kz'),
        '2026-02-28', 300000.00, '2026-02-01', true
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'erlan.zh@drivingschool.kz'),
        '2026-02-28', 320000.00, '2026-02-01', true
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'damir.a@drivingschool.kz'),
        '2026-02-28', 310000.00, '2026-02-01', true
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'bekzat.n@drivingschool.kz'),
        '2026-03-31', 360000.00, '2026-03-01', true
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'aidar.s@drivingschool.kz'),
        '2026-03-31', 310000.00, '2026-03-01', false
    );
 
-- lessons
insert into driving_school.lessons (instructor_id, vehicle_id, student_id, lesson_date, duration_hours, hourly_rate, lesson_status) values
    (
        (select instructor_id from driving_school.instructors where email = 'bekzat.n@drivingschool.kz'),
        (select vehicle_id from driving_school.vehicles where plate_number = '077 AA 01'),
        (select student_id from driving_school.students where email = 'moldyr.olzhabayeva@gmail.com'),
        '2026-02-10', 2, 40.00, 'completed'
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'bekzat.n@drivingschool.kz'),
        (select vehicle_id from driving_school.vehicles where plate_number = '077 AA 01'),
        (select student_id from driving_school.students where email = 'assylai.zhumakulova@gmail.com'),
        '2026-02-11', 2, 40.00, 'completed'
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'aidar.s@drivingschool.kz'),
        (select vehicle_id from driving_school.vehicles where plate_number = '077 AB 01'),
        (select student_id from driving_school.students where email = 'moldyr.olzhabayeva@gmail.com'),
        '2026-02-15', 3, 40.00, 'completed'
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'erlan.zh@drivingschool.kz'),
        (select vehicle_id from driving_school.vehicles where plate_number = '077 AC 01'),
        (select student_id from driving_school.students where email = 'aruzhan.khismetova@gmail.com'),
        '2026-02-20', 2, 40.00, 'completed'
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'damir.a@drivingschool.kz'),
        (select vehicle_id from driving_school.vehicles where plate_number = '077 AD 01'),
        (select student_id from driving_school.students where email = 'inabat.kairakbay@gmail.com'),
        '2026-03-05', 2, 40.00, 'completed'
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'damir.a@drivingschool.kz'),
        (select vehicle_id from driving_school.vehicles where plate_number = '077 AD 01'),
        (select student_id from driving_school.students where email = 'assel.balgabay@gmail.com'),
        '2026-03-06', 3, 40.00, 'completed'
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'askhat.o@drivingschool.kz'),
        (select vehicle_id from driving_school.vehicles where plate_number = '077 AE 01'),
        (select student_id from driving_school.students where email = 'aiken.amanbay@gmail.com'),
        '2026-03-15', 2, 40.00, 'completed'
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'askhat.o@drivingschool.kz'),
        (select vehicle_id from driving_school.vehicles where plate_number = '077 AE 01'),
        (select student_id from driving_school.students where email = 'aisha.zhumagali@gmail.com'),
        '2026-03-20', 2, 40.00, 'completed'
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'sanzhar.t@drivingschool.kz'),
        (select vehicle_id from driving_school.vehicles where plate_number = '077 AF 01'),
        (select student_id from driving_school.students where email = 'aktoty.shakhmet@gmail.com'),
        '2026-04-10', 3, 40.00, 'scheduled'
    ),
    (
        (select instructor_id from driving_school.instructors where email = 'sanzhar.t@drivingschool.kz'),
        (select vehicle_id from driving_school.vehicles where plate_number = '077 AF 01'),
        (select student_id from driving_school.students where email = 'raikhan.sakhtashova@gmail.com'),
        '2026-04-12', 2, 40.00, 'scheduled'
    );
 
-- payments
insert into driving_school.payments (student_id, amount, payment_date) values
    ((select student_id from driving_school.students where email = 'moldyr.olzhabayeva@gmail.com'),   200000.00, '2026-02-01'),
    ((select student_id from driving_school.students where email = 'assylai.zhumakulova@gmail.com'),  200000.00, '2026-02-03'),
    ((select student_id from driving_school.students where email = 'aruzhan.khismetova@gmail.com'),   150000.00, '2026-02-05'),
    ((select student_id from driving_school.students where email = 'assylai.amirzhankyz@gmail.com'),  200000.00, '2026-02-10'),
    ((select student_id from driving_school.students where email = 'inabat.kairakbay@gmail.com'),     200000.00, '2026-02-15'),
    ((select student_id from driving_school.students where email = 'assel.balgabay@gmail.com'),       250000.00, '2026-03-01'),
    ((select student_id from driving_school.students where email = 'aktoty.shakhmet@gmail.com'),      200000.00, '2026-03-15'),
    ((select student_id from driving_school.students where email = 'raikhan.sakhtashova@gmail.com'),  220000.00, '2026-03-20');
 
-- attendance 
insert into driving_school.attendance (student_id, lesson_id, student_present, notes)
select
    l.student_id,
    l.lesson_id,
    true,
    'Attended on time'
from driving_school.lessons l
where l.lesson_status = 'completed';
 
-- exams
insert into driving_school.exams (student_id, exam_type, exam_date, score, is_passed) values
    (
        (select student_id from driving_school.students where email = 'moldyr.olzhabayeva@gmail.com'),
        'theoretical', '2026-03-01', 85, true
    ),
    (
        (select student_id from driving_school.students where email = 'moldyr.olzhabayeva@gmail.com'),
        'practical', '2026-03-15', 78, true
    ),
    (
        (select student_id from driving_school.students where email = 'assylai.zhumakulova@gmail.com'),
        'theoretical', '2026-03-05', 90, true
    ),
    (
        (select student_id from driving_school.students where email = 'aruzhan.khismetova@gmail.com'),
        'theoretical', '2026-03-10', 55, false
    ),
    (
        (select student_id from driving_school.students where email = 'inabat.kairakbay@gmail.com'),
        'theoretical', '2026-04-01', 88, true
    ),
    (
        (select student_id from driving_school.students where email = 'assel.balgabay@gmail.com'),
        'theoretical', '2026-04-05', 72, true
    );
 
 
update driving_school.students
set is_premium = true
where student_id in (
    select student_id
    from driving_school.lessons
    where lesson_status = 'completed'
    group by student_id
    having sum(duration_hours) >= 5
);

update driving_school.lessons
set hourly_rate = hourly_rate * 1.10
from (
    select instructor_id
    from driving_school.lessons
    where lesson_status = 'completed'
    group by instructor_id
    having count(*) >= 2
) as top_instructors
where driving_school.lessons.instructor_id = top_instructors.instructor_id
  and driving_school.lessons.lesson_status = 'scheduled';
 
begin;
delete from driving_school.lessons
where lesson_status = 'cancelled'
returning lesson_id;
rollback;
 
drop role if exists driving_school_readonly;
drop role if exists driving_school_writer;

create role driving_school_readonly;
create role driving_school_writer;
 
grant select on all tables in schema driving_school to driving_school_readonly;
 
grant insert, update on driving_school.students to driving_school_writer;

revoke update on driving_school.students from driving_school_writer;



SELECT 
    s.student_id AS "ID Студента",
    s.full_name AS "ФИО Студента",
    b.branch_name AS "Филиал",
    c.category_code AS "Категория",
    c.description AS "Описание прав",
    s.enrollment_date AS "Дата записи"
FROM driving_school.students s
JOIN driving_school.branches b ON s.branch_id = b.branch_id
JOIN driving_school.categories c ON s.category_id = c.category_id;


SELECT 
    l.lesson_id AS "ID Урока",
    l.lesson_date AS "Дата занятия",
    s.full_name AS "Студент",
    i.full_name AS "Инструктор",
    v.model AS "Машина",
    v.plate_number AS "Гос. номер",
    l.duration_hours AS "Часы",
    l.total_price AS "Общая стоимость (₸)"
FROM driving_school.lessons l
JOIN driving_school.students s ON l.student_id = s.student_id
JOIN driving_school.instructors i ON l.instructor_id = i.instructor_id
JOIN driving_school.vehicles v ON l.vehicle_id = v.vehicle_id;