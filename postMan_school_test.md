{
    "message": "Schools fetched successfully",
    "count": 3,
    "data": [
        {
            "id": 2,
            "name": "Maggotty High",
            "moey_school_code": null,
            "short_code": null,
            "parish": "Kingston",
            "school_type": "primary",
            "is_shift_school": 0,
            "default_shift_type": "whole_day",
            "latitude": "18.012345",
            "longitude": "-76.789040",
            "radius_meters": 200,
            "timezone": "America/Jamaica",
            "is_active": 1
        },
        {
            "id": 1,
            "name": "Papine High",
            "moey_school_code": null,
            "short_code": null,
            "parish": "Kingston",
            "school_type": "secondary",
            "is_shift_school": 0,
            "default_shift_type": "whole_day",
            "latitude": "18.012345",
            "longitude": "-76.789040",
            "radius_meters": 200,
            "timezone": "America/Jamaica",
            "is_active": 1
        },
        {
            "id": 3,
            "name": "St. Catherine High",
            "moey_school_code": null,
            "short_code": null,
            "parish": "St. Catherine",
            "school_type": "secondary",
            "is_shift_school": 0,
            "default_shift_type": "whole_day",
            "latitude": "17.997000",
            "longitude": "-76.876500",
            "radius_meters": 150,
            "timezone": "America/Jamaica",
            "is_active": 1
        }
    ]
}

{
    "message": "School fetched successfully",
    "data": {
        "id": 1,
        "name": "Papine High",
        "moey_school_code": null,
        "short_code": null,
        "parish": "Kingston",
        "school_type": "secondary",
        "is_shift_school": 0,
        "default_shift_type": "whole_day",
        "latitude": "18.012345",
        "longitude": "-76.789040",
        "radius_meters": 200,
        "timezone": "America/Jamaica",
        "is_active": 1
    }
}


//. to post an school. here 

{
    "message": "School created successfully",
    "data": {
        "id": 4,
        "name": "Kingston Technical High",
        "moey_school_code": "MOE-KTH-001",
        "short_code": "KTH",
        "parish": "Kingston",
        "school_type": "secondary",
        "is_shift_school": 1,
        "default_shift_type": "morning",
        "latitude": "17.997700",
        "longitude": "-76.789000",
        "radius_meters": 200,
        "timezone": "America/Jamaica",
        "is_active": 1
    }
}



    "status": "error",
    "message": "Forbidden: insufficient permissions"
}
{
    "status": "error",
    "message": "Forbidden: insufficient permissions"
}
 this is error here that imn. getting ok ?



 // update school 

 {
    "message": "School updated successfully",
    "data": {
        "id": 1,
        "name": "Papine High",
        "moey_school_code": null,
        "short_code": null,
        "parish": "Kingston",
        "school_type": "secondary",
        "is_shift_school": 0,
        "default_shift_type": "whole_day",
        "latitude": "18.012345",
        "longitude": "-76.789040",
        "radius_meters": 250,
        "timezone": "America/Jamaica",
        "is_active": 1
    }
}

//. get. all student here 

{
    "message": "Students fetched successfully",
    "count": 3,
    "data": [
        {
            "student_id": 4,
            "user_id": 4,
            "email": "tia.clarke@student.jm",
            "first_name": "Tia",
            "last_name": "Clarke",
            "student_code": null,
            "sex": null,
            "date_of_birth": null,
            "current_shift_type": "whole_day",
            "phone_number": null,
            "status": "active",
            "homeroom_class_id": 2,
            "class_name": "Grade 9 Red",
            "grade_level": "Grade 9"
        },
        {
            "student_id": 2,
            "user_id": 2,
            "email": "shanice.davis@student.jm",
            "first_name": "Shanice",
            "last_name": "Davis",
            "student_code": null,
            "sex": null,
            "date_of_birth": null,
            "current_shift_type": "whole_day",
            "phone_number": null,
            "status": "active",
            "homeroom_class_id": 2,
            "class_name": "Grade 9 Red",
            "grade_level": "Grade 9"
        },
        {
            "student_id": 3,
            "user_id": 3,
            "email": "malik.grant@student.jm",
            "first_name": "Malik",
            "last_name": "Grant",
            "student_code": null,
            "sex": null,
            "date_of_birth": null,
            "current_shift_type": "whole_day",
            "phone_number": null,
            "status": "active",
            "homeroom_class_id": 2,
            "class_name": "Grade 9 Red",
            "grade_level": "Grade 9"
        }
    ]
}



//. to. get a single id 

{
    "message": "Student fetched successfully",
    "data": {
        "student_id": 4,
        "user_id": 4,
        "email": "tia.clarke@student.jm",
        "first_name": "Tia",
        "last_name": "Clarke",
        "student_code": null,
        "sex": null,
        "date_of_birth": null,
        "current_shift_type": "whole_day",
        "phone_number": null,
        "status": "active",
        "homeroom_class_id": 2,
        "class_name": "Grade 9 Red",
        "grade_level": "Grade 9"
    }
}


// create a student here

    "message": "Student enrolled successfully",
    "data": {
        "student_id": 11,
        "user_id": 8,
        "email": "john.smith@student.jm",
        "first_name": "John",
        "last_name": "Smith",
        "student_code": "STU-2026-001",
        "sex": "male",
        "date_of_birth": null,
        "current_shift_type": "whole_day",
        "phone_number": "8761234567",
        "status": "active",
        "homeroom_class_id": 1,
        "class_name": "10A",
        "grade_level": "Grade 10"
    }

// update a student 
{
    "message": "Student updated successfully",
    "data": {
        "student_id": 4,
        "user_id": 4,
        "email": "tia.clarke@student.jm",
        "first_name": "Tia",
        "last_name": "Clarke",
        "student_code": null,
        "sex": null,
        "date_of_birth": null,
        "current_shift_type": "morning",
        "phone_number": "8769999999",
        "status": "active",
        "homeroom_class_id": 2,
        "class_name": "Grade 9 Red",
        "grade_level": "Grade 9"
    }
}

    "message": "Student deactivated successfully"
}