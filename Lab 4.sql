/*1. В анонимном PL/SQL блоке распечатать все пифагоровы числа, меньшие 25 
(для печати использовать пакет dbms_output, процедуру put_line).*/

declare
  max_number int := 25;
begin
  for i in 1..max_number loop
    for j in i..max_number loop
      for k in j..max_number loop
        if i*i + j*j = k*k then
          dbms_output.put_line(i || ' ' || j || ' ' || k || '  ' || i*i || '+' || j*j || '=' || k*k);
        end if;
      end loop;
    end loop;
  end loop;
end;
/

/*2. Переделать предыдущий пример, чтобы для определения, что 3 числа пифагоровы использовалась функция.*/

create function fn_pifagor_check_cond(
  i int,
  j int,
  k int
) return boolean
is
begin
  return (i*i + j*j) = k*k;
end;
  
declare
  max_number int := 25;
begin
  for i in 1..max_number loop
    for j in i..max_number loop
      for k in j..max_number loop
        if fn_pifagor_check_cond(i, j, k) then
          dbms_output.put_line(i || ' ' || j || ' ' || k || '  ' || i*i || '+' || j*j || '=' || k*k);
        end if;
      end loop;
    end loop;
  end loop;
end;
/

/*3. Написать хранимую процедуру, которой передается ID сотрудника и которая увеличивает ему зарплату на 10%,
если в 2000 году у сотрудника были продажи. Использовать выборку количества заказов за 2000 год в переменную.
А затем, если переменная больше 0, выполнить update данных.*/

select  o.*
  from  orders o
  where date'2000-01-01' <= o.order_date and o.order_date < date'2001-01-01'
  order by  o.sales_rep_id
;
  
create procedure pr_increase_salary(par_id employees.employee_id%type)
is
  var_orders int;
begin
  select  count(o.order_id)
    into  var_orders
    from  orders o
    where o.sales_rep_id = par_id and
          date'2000-01-01' <= o.order_date and o.order_date < date'2001-01-01';
  if var_orders > 0 then
    update  employees e
      set   e.salary = e.salary * 1.1
      where e.employee_id = par_id;
  end if;
end;
/

declare
  var_order_count int;
  var_salary employees.salary%type;
  var_emp_id employees.employee_id%type := 155;
begin
  select  e.salary
    into  var_salary
    from  employees e
    where e.employee_id = var_emp_id;
  dbms_output.put_line('before:' || '' || var_salary);
  pr_increase_salary(var_emp_id);
  select  e.salary
    into  var_salary
    from  employees e
    where e.employee_id = var_emp_id;
  dbms_output.put_line('after:' || '' ||var_salary);
end;
/

/*4. Проверить корректность данных о заказах, а именно, что поле ORDER_TOTAL равно сумме UNIT_PRICE * QUANTITY 
по позициям каждого заказа. Для этого создать хранимую процедуру, в которой будет в цикле for проход по всем заказам,
далее по конкретному заказу отдельным select-запросом будет выбираться сумма по позициям данного заказа 
и сравниваться с ORDER_TOTAL. Для «некорректных» заказов распечатать код заказа, дату заказа, заказчика и менеджера.*/

create procedure pr_check_order_total
is
  var_order_total orders.order_total%type;
  var_real_price number;
begin
  for i_order in (
    select  o.*
      from  orders o
  ) loop
    var_order_total := i_order.order_total;
    select  sum(oi.unit_price * oi.quantity)
      into  var_real_price
      from  order_items oi
      where oi.order_id = i_order.order_id;
    if var_real_price <> var_order_total then
      dbms_output.put_line(i_order.order_id || ' ' || i_order.order_date || ' ' || i_order.customer_id || ' ' || i_order.sales_rep_id);
    end if;
  end loop;
end;
/
  
declare
begin
  pr_check_order_total();
end;
/

/*5. Переписать предыдущее задание с использованием явного курсора.*/

create procedure pr_check_order_total_explict_cursor
is
  cursor cur_check is
    select  o.order_id,
            oi.real_price,
            o.order_total,
            o.order_date,
            o.customer_id,
            o.sales_rep_id
      from  orders o
            inner join (select  sum(oi.unit_price * oi.quantity) as real_price,
                                oi.order_id
                          from  order_items oi
                          group by oi.order_id
                  ) oi on
                    oi.order_id = o.order_id;

  var_order cur_check%rowtype;
begin
  open cur_check;
  loop
    fetch cur_check into var_order;
    exit when cur_check%notfound;
    if var_order.order_total <> var_order.real_price then
      dbms_output.put_line(var_order.order_id || ' ' || var_order.order_date || ' ' || var_order.customer_id || ' ' || var_order.sales_rep_id);
    end if;
  end loop;        
end;
/

declare
begin
  pr_check_order_total_explict_cursor();
end;
/

/*6. Написать функцию, в которой будет создан тестовый клиент, которому будет сделан заказ
на текущую дату из одной позиции каждого товара на складе. Имя тестового клиента и ID склада передаются в качестве параметров.
Функция возвращает ID созданного клиента.*/

create function fn_make_test_order(
   par_first_name in customers.cust_first_name%type,
   par_last_name in customers.cust_last_name%type,
   par_warehouse_id in warehouses.warehouse_id%type
) return customers.customer_id%type
is 
  var_customer_id customers.customer_id%type;
  var_order_id orders.order_id%type;
  var_line_item_id order_items.line_item_id%type := 1;
  var_order_total orders.order_total%type := 0;
begin
  insert into customers (cust_first_name, cust_last_name)
    values (par_first_name, par_last_name)
    returning customer_id into var_customer_id;
  insert into orders (order_date, customer_id)
    values (sysdate, var_customer_id)
    returning order_id into var_order_id;
  for i_product in (
    select pi.*
      from  inventories inv
            join product_information pi on 
              pi.product_id = inv.product_id
      where inv.warehouse_id = par_warehouse_id and
            inv.quantity_on_hand > 0
  ) loop
    insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
      values (var_order_id, var_line_item_id, i_product.product_id, i_product.list_price, 1);
    var_line_item_id := var_line_item_id + 1;
    var_order_total := var_order_total + i_product.list_price;
  end loop;
  update  orders 
     set  order_total = var_order_total
    where order_id = var_order_id;
  return var_customer_id;
end;
/

declare
begin
  dbms_output.put_line(fn_make_test_order('Grigorev', 'Vladimir', 1));
end;
/

select  oi.*,
        c.customer_id,
        c.cust_first_name,
        c.cust_last_name
  from  orders o left join customers c 
          on c.customer_id = o.customer_id
        left join order_items oi
          on o.order_id = oi.order_id
  where c.customer_id = 1000
;

select  count(distinct oi.line_item_id)
  from  order_items oi
;

/*7. Добавить в предыдущую функцию проверку на существование склада с переданным ID. 
Для этого выбрать склад в переменную типа «запись о складе» и перехватить исключение no_data_found, 
если оно возникнет. В обработчике исключения выйти из функции, вернув null.*/

create function fn_make_test_order_expr_example(
     par_first_name in customers.cust_first_name%type,
     par_last_name in customers.cust_last_name%type,
     par_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type
  is 
    var_warehouse warehouses%rowtype;
    var_customer_id customers.customer_id%type;
    var_order_id orders.order_id%type;
    var_line_item_id order_items.line_item_id%type := 1;
    var_order_total orders.order_total%type := 0;
  begin
    begin
      select  *
        into  var_warehouse
        from  warehouses w
        where w.warehouse_id = par_warehouse_id;
    exception
    when no_data_found then
      return null;
    end;
    insert into customers (cust_first_name, cust_last_name)
      values (par_first_name, par_last_name)
      returning customer_id into var_customer_id;
    insert into orders (order_date, customer_id)
      values (sysdate, var_customer_id)
      returning order_id into var_order_id;
    for i_product in (select pi.*
                          from  inventories inv
                                join product_information pi on 
                                  pi.product_id = inv.product_id
                          where inv.warehouse_id = par_warehouse_id and
                                inv.quantity_on_hand > 0) loop
      insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
        values (var_order_id, var_line_item_id, i_product.product_id, i_product.list_price, 1);
      var_line_item_id := var_line_item_id + 1;
      var_order_total := var_order_total + i_product.list_price;
    end loop;
    update  orders 
         set  order_total = var_order_total
        where order_id = var_order_id;
      return var_customer_id;
    return var_customer_id;
end;
/

declare
begin
  dbms_output.put_line(fn_make_test_order_expr_example('Grigorev', 'Vladimir', 1));
end;
/

/*8. Написанные процедуры и функции объединить в пакет FIRST_PACKAGE.*/

create or replace package first_package as  
  function fn_pifagor_check_cond(
    i int,
    j int,
    k int
  ) return boolean;

  procedure pr_increase_salary(par_id employees.employee_id%type);

  procedure pr_check_order_total;

  procedure pr_check_order_total_explict_cursor;

  function fn_make_test_order(
     par_first_name in customers.cust_first_name%type,
     par_last_name in customers.cust_last_name%type,
     par_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type;
  
  function fn_make_test_order_expr_example(
     par_first_name in customers.cust_first_name%type,
     par_last_name in customers.cust_last_name%type,
     par_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type;
end first_package;
/

/*
9. Написать функцию, которая возвратит таблицу (table of record), содержащую информацию 
о частоте встречаемости отдельных символов во всех названиях (и описаниях) товара на заданном языке 
(передается код языка, а также параметр, указывающий, учитывать ли описания товаров). 
Возвращаемая таблица состоит из 2-х полей: символ, частота встречаемости в виде частного от кол-ва данного символа 
к количеству всех символов в названиях (и описаниях) товара.
*/

create type tp_char_result as 
object(
  ch nchar(1), 
  freq number
);
/
create type tp_char_result_table as
table of tp_char_result;
/
create function fn_char_find_freq(
  par_lang_id in product_descriptions.language_id%type,
  par_description in int
) return tp_char_result_table
is 
  type tp_char_result_indexed_table is 
    table of tp_char_result index by binary_integer;
  var_result_table tp_char_result_table;
  var_indexed_table tp_char_result_indexed_table;
  var_ch nchar(1);
  var_code binary_integer;
begin 
  var_result_table := tp_char_result_table();
  for i_pd in (select  *
                 from  product_descriptions pd
                 where pd.language_id = par_lang_id
  ) loop
    for i_l in 1..length(i_pd.translated_name) loop
      var_ch := substr(i_pd.translated_name, i_l, 1);
      var_code := ascii(var_ch);
      if not var_indexed_table.exists(var_code) then
        var_indexed_table(var_code) := tp_char_result(var_ch, 0);
      end if;
      var_indexed_table(var_code).freq := var_indexed_table(var_code).freq + 1;
    end loop;
  end loop;
  if par_description>0 then 
    for i_pd in (select  *
                   from  product_descriptions pd
                   where pd.language_id = par_lang_id
    ) loop
      for i_l in 1..length(i_pd.translated_description) loop
        var_ch := substr(i_pd.translated_description, i_l, 1);
        var_code := ascii(var_ch);
        if not var_indexed_table.exists(var_code) then
          var_indexed_table(var_code) := tp_char_result(var_ch, 0);
        end if;
        var_indexed_table(var_code).freq := var_indexed_table(var_code).freq + 1;
      end loop;
    end loop;
  end if;
  var_code := var_indexed_table.first;
  while var_code is not null
    loop
      var_result_table.extend(1);
      var_result_table(var_result_table.last) := var_indexed_table(var_code);
      var_code := var_indexed_table.next(var_code);
    end loop;
  return var_result_table;
end;
/
declare
  var_result tp_char_result_table;
begin
  var_result := fn_char_find_freq('RU', 1);
  for i in 1..var_result.count
    loop
      dbms_output.put_line(var_result(i).ch || ' ' || var_result(i).freq);
    end loop;
end;
/
select  *
  from  table(cast(fn_char_find_freq('RU', 1) as tp_char_result_table))
;
/

/*
10. Написать функцию, которой передается sys_refcursor и которая по данному курсору формирует HTML-таблицу,
содержащую информацию из курсора. Тип возвращаемого значения – clob.
*/

declare
  var_cur sys_refcursor;
  var_result clob;
  function get_html_table(par_cur in out sys_refcursor)
    return clob
  is
    var_cur sys_refcursor := par_cur;
    var_cn integer;
    var_cols_desc dbms_sql.desc_tab2;
    var_cols_count integer;
    var_temp integer;
    var_result clob;
    var_str varchar2(32767);
  begin
    dbms_lob.createtemporary(var_result, true);
    var_cn := dbms_sql.to_cursor_number(var_cur);
    dbms_sql.describe_columns2(var_cn, var_cols_count, var_cols_desc);
    for i_index in 1 .. var_cols_count loop
      dbms_sql.define_column(var_cn, i_index, var_str, 1000);
    end loop;
    dbms_lob.append(var_result, '<table><tr>');
    for i_index in 1..var_cols_count loop
      dbms_lob.append(var_result, '<th>' || var_cols_desc(i_index).col_name || '</th>');
    end loop;
    dbms_lob.append(var_result, '</tr>');
    loop
      var_temp:=dbms_sql.fetch_rows(var_cn);
      exit when var_temp = 0;
      dbms_lob.append(var_result, '<tr>');
      for i_index in 1 .. var_cols_count
        loop
          dbms_sql.column_value(var_cn, i_index, var_str);
          dbms_lob.append(var_result, '<td>' || var_str || '</td>');
        end loop;
      dbms_lob.append(var_result, '</tr>');
    end loop;
    dbms_lob.append(var_result, '</table>');
    return var_result;
  end;
begin
  open var_cur for
    select j.* 
      from jobs j;
  var_result := get_html_table(var_cur);
  dbms_output.put_line(var_result);
end;
/