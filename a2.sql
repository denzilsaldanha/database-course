  --List all the editors.
	create or replace view Q1(Name) as Select distinct Person.Name from
		 Person Inner Join Proceeding on Person.PersonId =  Proceeding.EditorId;

--List all the editors that have authored a paper.
	create or replace view Q2(Name) as Select distinct Person.Name from Person 
		Inner Join RelationPersonInProceeding on Person.PersonId = RelationPersonInProceeding.PersonId;

--List all the editors that have authored a paper in the proceeding that they have edited.
	create or replace view Q3(Name) as Select Distinct Person.Name from Person Inner Join Proceeding P on  Person.PersonId = P.EditorId 
    	Inner Join RelationPersonInProceeding R on P.EditorId = R.PersonId Inner Join InProceeding I on 
    	R.InProceedingId = I.InProceedingId And I.ProceedingId =  P.ProceedingId;

--For all editors that have authored a paper in a proceeding that they have edited, list the title of those papers.
	create or replace view Q4(Title) as Select Distinct I.Title from Proceeding P Inner Join RelationPersonInProceeding R 
    	on P.EditorId = R.PersonId Inner Join InProceeding I on R.InProceedingId = I.InProceedingId And I.ProceedingId =  P.ProceedingId;

--Find the title of all papers authored by an author with last name "Clark".
	create or replace view Q5(Title) as select Distinct I.title from (select PersonId from Person where Name Like '%Clark' or Name Like '%clark') 
    	as G Inner Join RelationPersonInProceeding R on G.PersonId = R.PersonId  
    	Inner Join InProceeding I on I.InProceedingId = R.InProceedingId ;


--List the total number of papers published in each year, ordered by year in ascending order. Do not include papers with an unknown year of publication. Also do not include years with no publication.
    create or replace view Q6(Year, Total) as select year, count(P.year) from proceeding P Inner Join InProceeding I 
    	on I.ProceedingId=P.ProceedingId Group By Year Order By P.year;

--Find the most common publisher(s) (the name). (i.e., the publisher that has published the maximum total number of papers in the database).
	create or replace view Q7(Name) as select G.Name from 
		(Select Name, count(P.Name) maximum from publisher P Inner Join proceeding Pro on Pro.PublisherId = 
			P.PublisherId Group By Name Order By maximum Desc Limit 1) as G;


--Find the author(s) that co-authors the most papers (output the name). If there is more than one author with the same maximum number of co-authorships, output all of them.
    create or replace view q8sq (Name ,Total ) as select P.Name, count(P.Name) as maximum from Person P Inner Join RelationPersonInProceeding R
      on P.PersonId=R.PersonId Group By P.Name Order By maximum desc;
      create or replace view q8sq2(maximum) as select max(q.Total) from q8sq q;

    create or replace view Q8(Name) as select K.Name from q8sq  K  Inner Join q8sq2 Q on Q.maximum = K.Total;

--Find all the author names that never co-author (i.e., always published a paper as a sole author).

    create or replace view q9_sq as select P.Name, count(P.Name) maximum, P.PersonId from Person P Inner Join RelationPersonInProceeding R
      on P.PersonId=R.PersonId Group By P.PersonId Having Count(P.Name) = 1;

    create or replace view Q9(Name) as select K.Name from q9_sq K;


--For each author, list their total number of co-authors, ordered by the total number of co-authors in descending order, followed by author names in ascending order. For authors that never co-author, their total is 0. For example, assume John has written 2 papers so far: one with Jane, Peter; and one with Jane, David. Then the total number of co-authors for John is 3. In other words, it is the number of people that have written papers with John.
  create or replace view q10s1 (Author, CoAuthor) as
      select  distinct A.PersonId,B.PersonId from RelationPersonInProceeding A,RelationPersonInProceeding B
       where A.InProceedingId=B.InProceedingId and A.PersonID != B.PersonId Order By A.PersonId Asc;
  create or replace view q10s2 (Author, CoAuthor) as 
    select distinct R.PersonId, A.CoAuthor from q10s1 A Full Outer Join RelationPersonInProceeding R on A.Author=R.PersonId Order By R.PersonId ASc;
  create or replace view Q10(Name, Total) as select P.Name, COALESCE(Count(A.Author)-1,'0') authcount from q10s2 A 
    Inner Join Person P on P.PersonId=A.Author Group BY P.PersonId Order By authcount Desc, P.Name Asc ;

--Find all the author names that have never co-authored with any co-author of Richard (i.e. Richard is the author's first name), nor co-authored with Richard himself.
    create or replace view Q11_subquery as (select R.InProceedingId from RelationPersonInProceeding R Inner Join Person P on R.PersonId = P.PersonId
       where P.Name Like 'Richard%' or P.Name Like 'richard%'); 
    create or replace view Q11_q2(Name) as
      select P.Name, P.PersonId, R.InProceedingId from  RelationPersonInProceeding R Inner Join Q11_subquery on Q11_subquery.InProceedingId=R.InProceedingId Inner Join
      Person P on P.PersonId = R.PersonId;
    create or replace view Q11_q3(Name) as
      select  distinct P.Name, P.PersonId, R.InProceedingId from  RelationPersonInProceeding R Inner Join Q11_q2 q on q.PersonId = R.PersonId
      Inner Join
      Person P on P.PersonId = R.PersonId;
    create or replace view q11_sq(PersonID) as 
      select distinct  R.PersonID  from RelationPersonInProceeding R except select Q.PersonId from Q11_q3 Q;

    create or replace view  Q11(Name) as select P.Name from Person P Inner Join q11_sq Q on P.PersonId=Q.PersonId ;


--Output all the authors that have co-authored with or are indirectly linked to Richard (i.e. Richard is the author's first name). We define that a is indirectly linked to b if there exists a C p1, p1 C p2,..., pn C b, where x C y means x is co-authored with y.
  create or replace recursive view subordinates (PersonId, InProceedingId) as 
    Select P.PersonId , R.InProceedingId from Person P Inner Join RelationPersonInProceeding R on P.PersonId = R.PErsonId 
    where P.Name Like 'Richard%' or P.Name Like 'richard%'
    UNION 
    select R.PersonId, R.InProceedingId from RelationPersonInProceeding R
     Inner Join subordinates s ON S.InProceedingId= R.InProceedingId OR S.PersonId= R.PersonId;
     

    create or replace view Q12(Name) as select distinct P.Name from subordinates S Inner Join Person P on S.PersonId = P.PersonId
     where P.Name Not Like 'Richard%' And P.Name Not Like 'richard%';



--Output the authors name, their total number of publications, the first year they published, and the last year they published. Your output should be ordered by the total number of publications in descending order and then by name in ascending order. If none of their publications have year information, the word "unknown" should be output for both first and last years of their publications.
    create or replace view Q13(Author, Total, FirstYear, LastYear)
     as select P.Name, count(P.Name) as tnop, COALESCE(min(year),'Unknown'), COALESCE(max(year),'Unknown')  from Person P Inner Join
     RelationPersonInProceeding R on P.PersonId=R.PersonId
     Inner Join InProceeding I on I.InProceedingId=R.InProceedingId 
     Inner Join Proceeding Pro on Pro.ProceedingId=I.ProceedingId Group By P.PersonId Order By tnop Desc, P.Name ASc;


--Suppose that all papers that are in the database research area either contain the word or substring "data" (case insensitive) in their title or in a proceeding that contains the word or substring "data". Find the number of authors that are in the database research area. (We only count the number of authors and will not include an editor that has never published a paper in the database research area).
    create or replace view Q14sq(PersonId) as select R.PersonId from RelationPersonInProceeding R
     Inner Join Proceeding Pro on R.PersonId = Pro.EditorId;
    create or replace view q14sq2(PersonId) as select distinct R.PersonId
     from RelationPersonInProceeding R except select q.PersonId from Q14sq q;
    
    create or replace view Q14(Total) as select count(Distinct K.PersonId) from (select distinct q.PersonId from 
     Q14sq2 q Inner Join RelationPersonInProceeding R on R.PersonId = q.PersonId Inner Join  InProceeding I on 
    	I.InProceedingId=R.InProceedingId Inner Join Proceeding Pro on Pro.ProceedingId=I.ProceedingId 
     
    	where Pro.Title Like'%data%' Or Pro.Title Like '%Data%' Or I.Title Like'%data%' Or I.Title Like '%Data%') as k;


--Output the following information for all proceedings: editor name, title, publisher name, year, total number of papers in the proceeding. Your output should be ordered by the total number of papers in the proceeding in descending order, then by the year in ascending order, then by the title in ascending order.
  create or replace view number_of_papers(ID,Total) as select Pro.ProceedingID, count(Pro.ProceedingId) from 
    Proceeding Pro Inner Join InProceeding I on I.ProceedingId = Pro.ProceedingId Group By Pro.ProceedingId;

  create or replace view Q15(EditorName, Title, PublisherName, Year, Total) as select P.Name, Pro.Title,
    Pub.Name, Pro.Year , N.Total from Person P Inner Join Proceeding Pro on Pro.EditorId =P.PersonId Inner Join
    Publisher Pub on Pub.PublisherId=Pro.PublisherId Inner Join number_of_papers N on N.ID = ProceedingId Order BY
    N.Total Desc, Pro.Year Asc, Pro.Title Asc;

--Output the author names that have never co-authored (i.e., always published a paper as a sole author) nor edited a proceeding.
  create or replace view Q16(Name) as  select Distinct K.Name from q9_sq K Inner Join Proceeding P on K.PersonId != P.EditorId;

--Output the author name, and the total number of proceedings in which the author has at least one paper published, ordered by the total number of proceedings in descending order, and then by the author name in ascending order.
      
    create or replace view Q17(Name, Total) as select P.Name,Count(Pro.ProceedingId) nop from Person P Inner Join RelationPersonInProceeding R on
      P.PersonId=R.PersonId Inner Join InProceeding I on I.InProceedingId=R.InProceedingId Inner Join Proceeding Pro on Pro.ProceedingId = 
      I.ProceedingId Group by P.Name Having Count(Pro.ProceedingId)>=1 Order BY nop desc, P.Name asc ;

--Count the number of publications per author and output the minimum, average and maximum count per author for the database. Do not include papers that are not published in any proceedings.
    create or replace view q18sq(Total) as select count(R.PersonId) from Person P Inner Join RelationPersonInProceeding R on 
      P.PersonId=R.PersonId Inner  Join InProceeding I on R.InProceedingId = I.InProceedingId Inner Join Proceeding Pro on Pro.ProceedingId = I.ProceedingId
       Group BY P.PersonId;
    
    create or replace view Q18(MinPub, AvgPub, MaxPub) as select min(q.total), round(avg(q.total)), max(q.Total) from q18sq Q;

--Count the number of publications per proceeding and output the minimum, average and maximum count per proceeding for the database.

    create or replace view Q19(MinPub, AvgPub, MaxPub) as select min(q.total), round(avg(q.total)), max(q.Total) from number_of_papers Q;

/*Create a trigger on RelationPersonInProceeding, to check and disallow any insert or update of a paper in the 
RelationPersonInProceeding table from an author that is also the editor of the proceeding in which the paper has published. */

--create or replace view help1 as select R.PersonId,R.InProceedingId, P.ProceedingId from RelationPersonInProceeding R Inner Join 
  --InProceedingId I on R.InProceedingId = I.InProceedingId Inner Join 


CREATE OR REPLACE FUNCTION log_relation()
RETURNS trigger AS
$$
BEGIN
 IF New.PersonId =(Select Pro.EditorId From Proceeding Pro INNER JOIN 
    InProceeding I on I.ProceedingId=Pro.ProceedingId Where I.InProceedingId=New.InProceedingId)
 THEN
 RAISE EXCEPTION 'Editior Clash';

 End IF;
 RETURN  NEW;
END;
$$ LANGUAGE plpgsql;

 



CREATE  TRIGGER Trig_ON_RelationPersonInProceeding 
  BEFORE INSERT OR UPDATE
  ON RelationPersonInProceeding
  FOR EACH ROW
  EXECUTE PROCEDURE log_relation();

/*Create a trigger on Proceeding to check and disallow any insert or update of a proceeding in the Proceeding table with an editor 
that is also the author of at least one of the papers in the proceeding. */

CREATE OR REPLACE FUNCTION log_proceeding()
RETURNS trigger AS
$$
BEGIN
 IF New.EditorId IN (Select R.PersonId From RelationPersonInProceeding R INNER JOIN InProceeding I on 
     I.InProceedingId=R.InProceedingId Where I.ProceedingId=New.ProceedingID)
 THEN
 RAISE EXCEPTION 'Editior Clash';
 End IF;
 RETURN  NEW;
END;
$$ LANGUAGE plpgsql;


CREATE  TRIGGER Trig_ON_Proceeding
  BEFORE INSERT OR UPDATE
  ON Proceeding
  FOR EACH ROW
  EXECUTE PROCEDURE log_proceeding();


/*Create a trigger on InProceeding to check and disallow any insert or update of a proceeding in the InProceeding table with an 
editor of the proceeding that is also the author of at least one of the papers in the proceeding.*/
  CREATE OR REPLACE FUNCTION log_inproceeding()
RETURNS trigger AS
$$
BEGIN
 IF (select P.EditorId from  
    Proceeding P  where
   P.ProceedingId=New.ProceedingId) IN ( select 
    R.PersonId From RelationPersonInProceeding R Where R.InProceedingId=New.InProceedingId) 
 THEN
 RAISE EXCEPTION 'Proceeding Clash';
 End IF;
 RETURN  NEW;
END;
$$ LANGUAGE plpgsql;



CREATE  TRIGGER Trig_ON_InProceeding
  BEFORE INSERT OR UPDATE
  ON InProceeding
  FOR EACH ROW
  EXECUTE PROCEDURE log_inproceeding();
