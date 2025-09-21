package com.elgris.usersapi.service;

import com.elgris.usersapi.models.User;
import com.elgris.usersapi.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Cacheable(value = "users", key = "'all'")
    public List<User> getAllUsers() {
        System.out.println("Fetching all users from database");
        return userRepository.findAll();
    }

    @Cacheable(value = "users", key = "#username")
    public User getUserByUsername(String username) {
        System.out.println("Fetching user " + username + " from database");
        return userRepository.findByUsername(username);
    }

}