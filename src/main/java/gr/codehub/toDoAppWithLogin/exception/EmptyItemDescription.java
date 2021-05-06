package gr.codehub.toDoAppWithLogin.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class EmptyItemDescription extends RuntimeException {
    public EmptyItemDescription(String description) {
        super(description);
    }
}
