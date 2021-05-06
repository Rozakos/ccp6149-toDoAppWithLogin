package gr.codehub.toDoAppWithLogin.listener;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationListener;
import org.springframework.security.authentication.event.AuthenticationFailureBadCredentialsEvent;
import org.springframework.stereotype.Component;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/**
 * This class allows the system to listen to login events, mainly used to capture the email of a user that failed to
 * login and passing it to the redirection towards the login page
 */
@Component
public class BadCredentialsListener implements ApplicationListener<AuthenticationFailureBadCredentialsEvent> {

    private final HttpServletRequest request;

    /**
     * constructor of this class, correct way to set the autowired attributes
     *
     * @param request: the http request received from a user
     */
    @Autowired
    public BadCredentialsListener(HttpServletRequest request) {
        this.request = request;
    }

    /**
     * this method listens for application events, and specifically for bad credentials requests
     * and sets the email value in the form through a session attribute,
     * for the convenience of the user (so he does not have to type it again).
     *
     * @param event: an event triggered by the user (login failed)
     */
    @Override
    public void onApplicationEvent(AuthenticationFailureBadCredentialsEvent event) {
        //get the email that the user attempted to login with
        Object emailObj = event.getAuthentication().getPrincipal();
        //get the string email
        String email = emailObj.toString();
        //set for the upcoming session, the session of the request received
        HttpSession session = request.getSession();
        //set the userEmail attribute of the session
        session.setAttribute("username", email);
    }
}
