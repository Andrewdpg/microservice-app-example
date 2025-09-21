package com.elgris.usersapi.repository;

import com.elgris.usersapi.models.User;

import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, String> {
    User findOneByUsername(String username);
    User findByUsername(String username);
    User getByUsername(String username);
}
