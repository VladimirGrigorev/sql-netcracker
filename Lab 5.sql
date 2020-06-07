/*
Создать схему БД для фиксации успеваемости студентов.

Есть таблицы:
Специальности (просто справочник);
Учебный план (специальность, семестр, предмет, вид отчетности);
Студенты (фио, специальность, год поступления);
Оценки (студент, дата, оценка – предусмотреть неявку).
(Понятно, что указаны не все необходимые поля, а только список того, что должно быть обязательно).

В таблицах должны быть предусмотрены все ограничения целостности.

Создать триггеры для автоинкрементности первичных ключей.

Заполнить таблицы тестовыми данными.

Написать запрос, выводящий список должников на текущий момент времени (сколько семестров проучился студент вычислять из года поступления и текущей даты – написать для этого функцию). Должны выводиться поля: код студента, ФИО студента, курс, код предмета, название предмета, семестр, оценка (2 – если сдавал экзамен, нулл – если не сдавал).

Сделать из этого запроса представление.

Выбрать из представления студентов с 4-мя и более хвостами (на отчисление).
*/

create table specialties(
  spec_id number(4, 0),
  spec_name varchar2(63) not null,
  constraint spec_pk
    primary key (spec_id),
  constraint spec_name_uniq
    unique (spec_name)
);

create table subjects(
  subj_id number(4, 0),
  subj_name varchar(63) not null,
  constraint subj_pk
    primary key (subj_id),
  constraint subj_name_uniq
    unique (subj_name)
);

create table curriculums(
  curr_id number(10, 0),
  spec_id number(4, 0) not null,
  semester number(2, 0) not null,
  subj_id number(4, 0) not null,
  report_type varchar2(15) not null,
  constraint curr_pk 
    primary key (curr_id),
  constraint fk_specialties_curriculums
    foreign key (spec_id)
    references specialties(spec_id),
  constraint fk_subjects_curriculums
    foreign key (subj_id)
    references subjects(subj_id),
  constraint check_curriculums_report_type
    check (report_type in ('Credit', 'Credit_with_mark','Examination'))
);

create table students(
  stud_id number(12, 0),
  stud_name varchar2(255) not null,
  spec_id number(4,0) not null,
  year_of_entry number(5,0) not null,
  constraint stud_pk
    primary key (stud_id),
  constraint fk_specialties_students
    foreign key (spec_id)
    references specialties(spec_id)
);

create table marks ( 
  stud_id number(12, 0),
  curr_id number(10, 0),
  exam_date date,
  mark number(3, 0),
  constraint marks_pk 
    primary key (stud_id, curr_id, exam_date),
  constraint fk_students_marks
    foreign key (stud_id)
    references students(stud_id),
  constraint fk_subjects_marks
    foreign key (curr_id)
    references curriculums(curr_id)
);

create sequence spec_seq
  minvalue 1
  maxvalue 10000
  increment by 1
  nocache noorder nocycle
;
/
create trigger spec_tr_set_id
  before insert on specialties
  for each row
begin
  if :new.spec_id is null then
    select spec_seq.nextval
      into :new.spec_id 
      from dual;
  end if;
end;
/
alter trigger spec_tr_set_id enable;
/
create sequence curr_seq
  minvalue 1
  maxvalue 10000
  increment by 1
  nocache noorder nocycle
;
/
create trigger curr_tr_set_id
  before insert on curriculums
  for each row
begin
  if :new.curr_id is null then
    select curr_seq.nextval
      into :new.curr_id
      from dual;
  end if;
end;
/
alter trigger curr_tr_set_id enable;
/
create sequence stud_seq
  minvalue 1
  maxvalue 10000
  increment by 1
  nocache noorder nocycle
;
/
create trigger stud_tr_set_id
  before insert on students
  for each row
begin
  if :new.stud_id is null then
    select stud_seq.nextval
      into :new.stud_id
      from dual;
  end if;
end;
/
alter trigger stud_tr_set_id enable;
/
create sequence subj_seq
  minvalue 1
  maxvalue 10000
  increment by 1
  nocache noorder nocycle
;
/
create trigger subj_tr_set_id
  before insert on subjects
  for each row
begin
  if :new.subj_id is null then
    select subj_seq.nextval
      into :new.subj_id
      from dual;
  end if;
end;
/
alter trigger subj_tr_set_id enable;
/

insert all
  into specialties (spec_name) values ('IT')
  into specialties (spec_name) values ('Physics')
  into specialties (spec_name) values ('Chemistry')
  into specialties (spec_name) values ('Math')
  into specialties (spec_name) values ('Medicine')
select * from dual
;

insert all
  into students (stud_name, year_of_entry, spec_id) values ('Alexander', 2020, 1)
  into students (stud_name, year_of_entry, spec_id) values ('Vladimir', 2020, 2)
  into students (stud_name, year_of_entry, spec_id) values ('Nikolay', 2020, 3)
  into students (stud_name, year_of_entry, spec_id) values ('Maxim', 2020, 4)
  into students (stud_name, year_of_entry, spec_id) values ('Anna', 2020, 5)
select * from dual;

insert all
  into subjects (subj_name) values ('Geometry')    
  into subjects (subj_name) values ('English_language') 
  into subjects (subj_name) values ('History') 
  into subjects (subj_name) values ('Algebra') 
  into subjects (subj_name) values ('chemistry')  
  into subjects (subj_name) values ('Medicine')  
  into subjects (subj_name) values ('C++')     
select * from dual;


insert all
  into curriculums (spec_id, semester, subj_id, report_type) values (1, 1, 1, 'Examination')   
  into curriculums (spec_id, semester, subj_id, report_type) values (1, 1, 3, 'Examination') 
  into curriculums (spec_id, semester, subj_id, report_type) values (1, 1, 4, 'Examination') 
  into curriculums (spec_id, semester, subj_id, report_type) values (1, 1, 7, 'Examination')
  into curriculums (spec_id, semester, subj_id, report_type) values (2, 1, 1, 'Examination')   
  into curriculums (spec_id, semester, subj_id, report_type) values (2, 1, 3, 'Examination')   
  into curriculums (spec_id, semester, subj_id, report_type) values (2, 1, 4, 'Examination')   
  into curriculums (spec_id, semester, subj_id, report_type) values (2, 1, 2, 'Examination') 
  into curriculums (spec_id, semester, subj_id, report_type) values (2, 1, 7, 'Examination')
  
  into curriculums (spec_id, semester, subj_id, report_type) values (3, 1, 1, 'Examination')   
  into curriculums (spec_id, semester, subj_id, report_type) values (3, 1, 4, 'Examination')   
  into curriculums (spec_id, semester, subj_id, report_type) values (3, 1, 6, 'Examination') 
  
  into curriculums (spec_id, semester, subj_id, report_type) values (4, 1, 1, 'Examination') 
  into curriculums (spec_id, semester, subj_id, report_type) values (4, 1, 4, 'Examination')
  into curriculums (spec_id, semester, subj_id, report_type) values (4, 1, 5, 'Examination')  
  
  into curriculums (spec_id, semester, subj_id, report_type) values (5, 1, 1, 'Examination')   
  into curriculums (spec_id, semester, subj_id, report_type) values (5, 1, 2, 'Examination')   
  into curriculums (spec_id, semester, subj_id, report_type) values (5, 1, 4, 'Examination') 
  into curriculums (spec_id, semester, subj_id, report_type) values (5, 1, 7, 'Examination')
select * from dual;

insert all
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 1, date'2020-01-14', 5)
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 2, date'2020-01-17', 5)
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 3, date'2020-01-21', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (1, 4, date'2020-01-24', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 5, date'2020-01-14', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 6, date'2020-01-17', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 7, date'2020-01-21', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 8, date'2020-01-27', 3)
  into marks (student_id, curriculum_id, exam_date, mark) values (2, 9, date'2020-01-24', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 10, date'2020-01-14', 3)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 11, date'2020-01-21', 3)
  into marks (student_id, curriculum_id, exam_date, mark) values (3, 12, date'2020-01-17', 4)
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 13, date'2020-01-21', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 14, date'2020-01-17', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (4, 15, date'2020-01-14', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (5, 16, date'2020-01-14', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (5, 17, date'2020-01-21', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (5, 18, date'2020-01-17', 2)
  into marks (student_id, curriculum_id, exam_date, mark) values (5, 19, date'2020-01-24', 5)
select * from dual;

/
create or replace function fn_count_semester (
  par_stud_id in students.stud_id%type
) return number
is
  var_year_of_entry students.year_of_entry%type;
  var_years number;
  var_month number;
  var_semestrs number;
begin
  select s.year_of_entry
    into var_year_of_entry
    from students s
    where s.stud_id = par_stud_id;
  var_years := extract(year from sysdate) - var_year_of_entry;
  var_month := extract(month from sysdate);
  var_semestrs := var_years * 2;
  if (var_month < 2) then
    var_semestrs := var_semestrs - 1;
  end if;
  if (var_month >= 9) then 
    var_semestrs := var_semestrs + 1;
  end if;
  return var_semestrs;
end;
/

create or replace view v_academic_debts as
select  s.stud_id,
        s.stud_name,
        round(fn_count_semester(s.stud_id)/2) as course,
        sub.subj_id,
        sub.subj_name,
        cur.semester as semester
  from  students s
        inner join specialties sp on
          sp.spec_id = s.spec_id
        inner join curriculums cur on
          cur.spec_id = sp.spec_id and
          cur.semester < fn_count_semester(s.stud_id)
        inner join subjects sub on
          sub.subj_id = cur.subj_id
        left join marks m on
          m.stud_id = s.stud_id and
          m.curr_id = cur.curr_id
  where nvl(m.mark, 2) = 2
;

select * from v_academic_debts;

select  vad.stud_id,
        vad.stud_name, 
        count(vad.stud_id) as academic_debts_count
  from  v_academic_debts vad
  group by  vad.stud_id,
            vad.stud_name
  having  count(vad.stud_id) > 3
;