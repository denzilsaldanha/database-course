	-- COMP9311 18s2 Assignment 1
-- Schema for the myPhotos.net photo-sharing site
--
-- Written by:
--    Name:  <<YOUR NAME GOES HERE>>
--    Student ID:  <<YOUR STUDENT ID GOES HERE>>
--    Date:  ??/09/2018
--
-- Conventions:
-- * all entity table names are plural
-- * most entities have an artifical primary key called "id"
-- * foreign keys are named after either:
--   * the relationship they represent
--   * the table being referenced

-- Domains (you may add more)

create domain URLValue as
	varchar(100) check (value like 'http://%');

create domain EmailValue as
	varchar(100) check (value like '%@%.%');

create domain GenderValue as
	varchar(6) check (value in ('male','female'));

create domain GroupModeValue as
	varchar(15) check (value in ('private','by-invitation','by-request'));

create domain ContactListTypeValue as
	varchar(10) check (value in ('friends','family'));

create domain VisibilityValue as
	varchar(20) check (value in ('friends','family','private','friends+family','public'));

create domain SafetyLevelValue as
	varchar(10) check (value in ('safe','moderate', 'restricted'));

create domain NameValue as varchar(50);

create domain LongNameValue as varchar(100);


-- Tables (you must add more)

create table People (
	id          serial,
	family_name NameValue,
	given_names NameValue not null,
	email_address EmailValue not null UNIQUE,
	displayed_name LongNameValue,
	primary key (id)
);
create table Discussions(
	id serial,
	title NameValue,
	primary key (id)
);

create table "Users" (
	"user"  integer
			constraint ValidUser references People(id),
	date_registered Date,
	gender GenderValue,
	birthday Date,
	password varchar(50) not null,
	
	
	websites_owned URLValue UNIQUE,
	primary key ("user")
);

create table Photos (
	id serial,
	date_taken date,
	title NameValue not null,
	date_uploaded DATE default CURRENT_DATE,
	description text,
	technical_details text,
	safety_level SafetyLevelValue not null,
	visibility VisibilityValue not null,
	file_size SMALLINT,
	photo_has_discussion integer
			constraint ValidDiscussionID references Discussions(id),
	photo_owned_by_user integer
			constraint ValidUserOwned references "Users"("user"),
	primary key (id)
);

create table Groups (
	id serial,
	mode GroupModeValue not null,
	title varchar(50) not null,
	group_owned_by_user integer
			constraint ValidGroup references "Users"("user"),
	primary key (id)
);
create table Collections(
	id serial,
	title NameValue not null,
	description text,
	photo_keyed_in_collection integer
			constraint ValidPhotoId references Photos(id),
	user_owns_collection integer
			constraint ValidUserID references "Users"("user"),
	group_owns_collection integer
			constraint ValidCollectionsId references Groups(id),

	constraint DisjointTotal check
	((user_owns_collection is not null and group_owns_collection is null)
	 or
	 (user_owns_collection is null and group_owns_collection is not null )),
	primary key(id)
);

create table Contact_lists (
	id serial,
	type ContactListTypeValue,
	title varchar(50) not null,
	contact_list_owned_by_user integer
			constraint ValidContactList references "Users"("user"),
	primary key (id)
);




alter table "Users" 
		add column portrait integer
				constraint ValidPortraitID references Photos(id);



-- create table portrait(
-- 	user_id integer 
-- 			constraint ValidUserID references "Users"("user"),
-- 	photo_id integer
-- 			constraint ValidPhotoId references Photos(id),
-- 	primary key (user_id,photo_id)
-- );

create table Contact_lists_Member_People(
	people_id integer
			constraint ValidPeopleid references People(id),
	contact_lists_id integer
			constraint ValidContactListID references Contact_lists(id),
	primary key (people_id,contact_lists_id)
);

create table Groups_Member_Users(
	group_id integer
			constraint ValidGroupID references Groups(id),
	user_id integer	
			constraint ValidUserID references "Users"("user"),
	primary key(group_id,user_id)
);

create table tags(
	id serial,
	freq integer,
	name NameValue not null,
	primary key (id)
);

create table Users_have_tagged_Photos(
	tag_id integer
			constraint ValidTagId references tags(id),
	photo_id integer
			constraint ValidPhotoId references Photos(id),
	user_id integer
			constraint ValidUserID references "Users"("user"),
	when_tagged Timestamp default now(),

	primary key (user_id,tag_id,photo_id)
);

create table Users_rate_Photos(
	user_id integer
			constraint ValidUserID references "Users"("user"),
	photo_id integer
			constraint ValidPhotoId references Photos(id),
	when_rated Timestamp default now(),
	rating integer 
		check (rating >= 1 and rating <= 5),

	primary key (user_id,photo_id)

);


create table Photos_in_Collections(
	photo_id integer
			constraint ValidPhotoId references Photos(id),
	collections_id integer
			constraint ValidCollectionsId references Collections(id),
	"order" SMALLINT check( "order" > 0 ),
	primary key (photo_id,collections_id)
);

create table Comments(
	id serial,
	when_posted timestamp default now(),
	content text,
	discussion_id integer
			constraint ValidDiscussion references Discussions(id),
	user_authored_comment integer
			constraint ValidUserID references "Users"("user"),

	primary key(id)
);

alter table Comments 
		add column comment_replies_to integer
			constraint ValidComment references Comments(id);


create table Groups_have_discussion(
	discussion_id integer
			constraint ValidDiscussion references Discussions(id),
	group_id integer
			constraint ValidGroupID references Groups(id),
	primary key (discussion_id,group_id)
);