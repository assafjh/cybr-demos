package com.example.demo.repository;

import com.example.demo.model.Zoo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
    public interface ZooRepository extends JpaRepository<Zoo, Long> {
}
