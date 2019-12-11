db.createUser(
    {
        user: "lieder_user_1",
        pwd: "lieder_user_1",
        roles :[
            {
                role:"readWrite",
                db: "songsrepo"
            }
        ]
    }
)